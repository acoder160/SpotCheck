package spotcheck.repository;

import spotcheck.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Collection;
import java.util.Optional;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

    /**
     * Writes only bio and avatar. A full save after the slow AI checks would put back whatever else
     * changed meanwhile (a "log out everywhere", an account deletion). 0 = the account is gone.
     */
    @Modifying(clearAutomatically = true)
    @org.springframework.transaction.annotation.Transactional
    @Query("UPDATE User u SET u.bio = :bio, u.avatarUrl = :avatar WHERE u.id = :id AND u.deletedAt IS NULL")
    int updateProfile(@Param("id") Long id, @Param("bio") String bio, @Param("avatar") String avatar);
    // Spring crea la consulta SQL automáticamente por el nombre del metodo
    Optional<User> findByUsername(String username);
    Optional<User> findByEmail(String email);

    // Para comprobar si ya existe al registrarse
    Boolean existsByUsername(String username);
    Boolean existsByEmail(String email);

    // Reputación de denunciantes (decisiones de admin)
    @Modifying
    @Query("UPDATE User u SET u.reportsUpheld = u.reportsUpheld + 1 WHERE u.id IN :ids")
    int incrementReportsUpheld(@Param("ids") Collection<Long> ids);

    @Modifying
    @Query("UPDATE User u SET u.reportsRejected = u.reportsRejected + 1 WHERE u.id IN :ids")
    int incrementReportsRejected(@Param("ids") Collection<Long> ids);
}
