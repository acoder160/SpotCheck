package spotcheck.service;

import org.junit.jupiter.api.Test;
import spotcheck.dto.SpotDto;
import spotcheck.exception.ApiException;

import static org.junit.jupiter.api.Assertions.assertDoesNotThrow;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class SpotLocationCheckTest {

    // 0.001° of latitude is ~111 m
    private static SpotDto spotAt(Double userLat, Double userLng) {
        SpotDto dto = new SpotDto();
        dto.setLatitude(41.3833);
        dto.setLongitude(2.1667);
        dto.setUserLatitude(userLat);
        dto.setUserLongitude(userLng);
        return dto;
    }

    @Test
    void aSpotNextToTheUserIsAccepted() {
        assertDoesNotThrow(() -> SpotService.requireUserNearSpot(spotAt(41.3851, 2.1667)));  // ~200 m
    }

    @Test
    void aSpotFarFromTheUserIsRejectedWithTheDistance() {
        ApiException ex = assertThrows(ApiException.class,
                () -> SpotService.requireUserNearSpot(spotAt(41.3863, 2.1667)));  // ~334 m
        assertEquals("spot_too_far", ex.getCode());
        assertEquals(334L, ex.getDetails().get("meters"));
    }

    @Test
    void anOldClientWithoutPositionIsAskedToUpdate() {
        ApiException ex = assertThrows(ApiException.class, () -> SpotService.requireUserNearSpot(spotAt(null, null)));
        assertEquals("location_required", ex.getCode());
    }
}
