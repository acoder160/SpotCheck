package spotcheck;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import spotcheck.entity.User;
import spotcheck.repository.UserRepository;
import spotcheck.service.RefreshTokenService;

import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;

/** Refresh rotation on a real database: what a mocked repository can't show is what gets committed. */
class RefreshRotationIntegrationTest extends AbstractIntegrationTest {

    @Autowired private RefreshTokenService refreshTokenService;
    @Autowired private UserRepository userRepository;
    @Autowired private JdbcTemplate jdbc;

    private User newUser() {
        String run = UUID.randomUUID().toString().substring(0, 8);
        User u = new User();
        u.setUsername("rot" + run);
        u.setEmail("rot" + run + "@example.com");
        u.setPassword("not-a-real-hash");
        return userRepository.save(u);
    }

    private long activeSessions(User user) {
        return jdbc.queryForObject(
                "SELECT count(*) FROM refresh_sessions WHERE user_id = ? AND revoked_at IS NULL", Long.class, user.getId());
    }

    @Test
    void twoTabsSendingTheSameTokenBothStaySignedIn() {
        User user = newUser();
        String first = refreshTokenService.createSession(user).rawToken();

        String tabA = refreshTokenService.rotate(first).rawToken();
        String tabB = refreshTokenService.rotate(first).rawToken();   // a moment later, same old token

        assertNotEquals(tabA, tabB);
        assertNotNull(refreshTokenService.rotate(tabA));
        assertNotNull(refreshTokenService.rotate(tabB));
    }

    @Test
    void reusingAnOldTokenRevokesTheWholeFamilyForReal() {
        User user = newUser();
        String stolen = refreshTokenService.createSession(user).rawToken();
        refreshTokenService.rotate(stolen);
        // Past the grace window
        jdbc.update("UPDATE refresh_sessions SET revoked_at = now() - interval '1 minute' "
                + "WHERE user_id = ? AND revoked_at IS NOT NULL", user.getId());

        assertThrows(IllegalArgumentException.class, () -> refreshTokenService.rotate(stolen));

        // Re-read from the database: the revocation was committed, not rolled back with the exception
        assertEquals(0, activeSessions(user));
    }

    @Test
    void afterLogoutTheOldTokenGetsNoGrace() {
        User user = newUser();
        String old = refreshTokenService.createSession(user).rawToken();
        String current = refreshTokenService.rotate(old).rawToken();
        refreshTokenService.revoke(current);   // logout

        assertThrows(IllegalArgumentException.class, () -> refreshTokenService.rotate(old));
        assertEquals(0, activeSessions(user));
    }
}
