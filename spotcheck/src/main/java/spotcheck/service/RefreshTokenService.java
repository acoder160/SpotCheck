package spotcheck.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseCookie;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import spotcheck.entity.RefreshSession;
import spotcheck.entity.User;
import spotcheck.repository.RefreshSessionRepository;
import spotcheck.repository.UserRepository;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.HexFormat;
import java.util.UUID;

@Service
public class RefreshTokenService {

    public static final String COOKIE_NAME = "spotcheck_refresh";
    static final Duration ROTATION_GRACE = Duration.ofSeconds(10);
    /** Expired or revoked rows are kept this long (for "active sessions" history), then deleted. */
    private static final Duration KEEP_OLD_SESSIONS = Duration.ofDays(7);

    private final RefreshSessionRepository sessionRepository;
    private final UserRepository userRepository;
    private final SecureRandom secureRandom = new SecureRandom();

    @Value("${spotcheck.app.refreshExpirationMs}")
    private long refreshExpirationMs;

    @Value("${spotcheck.app.refreshCookieSecure:true}")
    private boolean secureCookie;

    @Value("${spotcheck.app.refreshCookieSameSite:Strict}")
    private String sameSite;

    public RefreshTokenService(RefreshSessionRepository sessionRepository, UserRepository userRepository) {
        this.sessionRepository = sessionRepository;
        this.userRepository = userRepository;
    }

    @Transactional
    public IssuedRefreshToken createSession(User user) {
        return createSession(user, UUID.randomUUID());
    }

    /**
     * Rotates a refresh token. Reusing an old one revokes its whole family (the token was probably
     * stolen). noRollbackFor: that revocation must be saved even though the call then fails.
     */
    @Transactional(noRollbackFor = IllegalArgumentException.class)
    public IssuedRefreshToken rotate(String rawToken) {
        RefreshSession current = sessionRepository.findByTokenHashForUpdate(hash(rawToken))
                .orElseThrow(() -> new IllegalArgumentException("Invalid refresh token"));

        LocalDateTime now = LocalDateTime.now();
        if (current.getExpiresAt().isBefore(now)) {
            revokeFamily(current.getFamilyId(), true);
            throw new IllegalArgumentException("Refresh token was revoked or expired");
        }
        if (current.getRevokedAt() != null) {
            // Two tabs (or a retry) sending the same token a moment apart: the second one gets its own
            // token in the same family. Only while the family is still live: after a logout it is not.
            if (current.getRevokedAt().isAfter(now.minus(ROTATION_GRACE))
                    && sessionRepository.existsByFamilyIdAndRevokedAtIsNullAndExpiresAtAfter(current.getFamilyId(), now)) {
                return createSession(current.getUser(), current.getFamilyId());
            }
            revokeFamily(current.getFamilyId(), true);
            throw new IllegalArgumentException("Refresh token was revoked or expired");
        }

        current.setRevokedAt(LocalDateTime.now());
        sessionRepository.save(current);
        return createSession(current.getUser(), current.getFamilyId());
    }

    @Transactional
    public void revoke(String rawToken) {
        sessionRepository.findByTokenHashForUpdate(hash(rawToken)).ifPresent(session -> {
            session.setRevokedAt(LocalDateTime.now());
            sessionRepository.save(session);
        });
    }

    @Transactional
    public void revokeAll(User user) {
        user.setTokenVersion(user.getTokenVersion() + 1);
        userRepository.save(user);
        sessionRepository.findByUserId(user.getId()).forEach(session -> {
            if (session.getRevokedAt() == null) {
                session.setRevokedAt(LocalDateTime.now());
            }
        });
    }

    /** Every rotation adds a row: without this the table only grows. */
    @org.springframework.scheduling.annotation.Scheduled(fixedDelayString = "${app.refresh.cleanup-interval-ms:21600000}",
            initialDelay = 60000)
    @Transactional
    public void deleteOldSessions() {
        sessionRepository.deleteOlderThan(LocalDateTime.now().minus(KEEP_OLD_SESSIONS));
    }

    public ResponseCookie createCookie(String rawToken) {
        return ResponseCookie.from(COOKIE_NAME, rawToken)
                .httpOnly(true)
                .secure(secureCookie)
                .sameSite(sameSite)
                .path("/api/auth")
                .maxAge(Duration.ofMillis(refreshExpirationMs))
                .build();
    }

    public ResponseCookie clearCookie() {
        return ResponseCookie.from(COOKIE_NAME, "")
                .httpOnly(true)
                .secure(secureCookie)
                .sameSite(sameSite)
                .path("/api/auth")
                .maxAge(Duration.ZERO)
                .build();
    }

    private IssuedRefreshToken createSession(User user, UUID familyId) {
        byte[] bytes = new byte[48];
        secureRandom.nextBytes(bytes);
        String rawToken = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);

        RefreshSession session = new RefreshSession();
        session.setUser(user);
        session.setTokenHash(hash(rawToken));
        session.setFamilyId(familyId);
        session.setExpiresAt(LocalDateTime.now().plus(Duration.ofMillis(refreshExpirationMs)));
        sessionRepository.save(session);
        return new IssuedRefreshToken(rawToken, user);
    }

    private void revokeFamily(UUID familyId, boolean reuseDetected) {
        sessionRepository.findByFamilyId(familyId).forEach(session -> {
            session.setRevokedAt(LocalDateTime.now());
            session.setReuseDetected(reuseDetected);
        });
    }

    private String hash(String rawToken) {
        try {
            byte[] digest = MessageDigest.getInstance("SHA-256")
                    .digest(rawToken.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(digest);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 is unavailable", exception);
        }
    }

    public record IssuedRefreshToken(String rawToken, User user) {}
}
