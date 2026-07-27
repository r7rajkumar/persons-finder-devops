package com.persons.finder.domain.services

import com.persons.finder.data.Location
import com.persons.finder.data.repositories.LocationRepository
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test

class LocationsServiceImplTest {

    private val locationRepository: LocationRepository = mockk()
    private val service = LocationsServiceImpl(locationRepository)

    @Test
    fun `findAround returns only locations within the radius`() {
        // Auckland CBD
        val origin = Location(referenceId = 1, latitude = -36.8485, longitude = 174.7633)
        // Hamilton, roughly 125km south of Auckland
        val farAway = Location(referenceId = 2, latitude = -37.7870, longitude = 175.2793)
        // Devonport, a couple of km across the harbour from the CBD
        val nearby = Location(referenceId = 3, latitude = -36.8330, longitude = 174.7970)

        every { locationRepository.findAll() } returns listOf(origin, farAway, nearby)

        val result = service.findAround(origin.latitude, origin.longitude, 10.0)

        assertEquals(setOf(1L, 3L), result.map { it.referenceId }.toSet())
        assertTrue(result.none { it.referenceId == 2L })
    }

    @Test
    fun `addLocation upserts via save`() {
        val location = Location(referenceId = 1, latitude = 1.0, longitude = 2.0)
        every { locationRepository.save(location) } returns location

        service.addLocation(location)

        verify(exactly = 1) { locationRepository.save(location) }
    }
}
