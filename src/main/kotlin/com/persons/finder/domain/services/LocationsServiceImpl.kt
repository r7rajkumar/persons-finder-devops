package com.persons.finder.domain.services

import com.persons.finder.data.Location
import com.persons.finder.data.repositories.LocationRepository
import org.springframework.stereotype.Service
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

@Service
class LocationsServiceImpl(
    private val locationRepository: LocationRepository
) : LocationsService {

    override fun addLocation(location: Location) {
        // save() on a JPA repo with an existing @Id acts as an upsert (update/create),
        // matching the controller's "update or create" contract.
        locationRepository.save(location)
    }

    override fun removeLocation(locationReferenceId: Long) {
        if (locationRepository.existsById(locationReferenceId)) {
            locationRepository.deleteById(locationReferenceId)
        }
    }

    override fun getLocation(referenceId: Long): Location? {
        return locationRepository.findById(referenceId).orElse(null)
    }

    override fun findAround(latitude: Double, longitude: Double, radiusInKm: Double): List<Location> {
        // NOTE (scaling): this filters in-memory using the Haversine formula, which is fine
        // for the small dataset in this assessment. At production scale this table should be
        // indexed geospatially (e.g. PostGIS ST_DWithin, or a geohash/H3 index) instead of a
        // full table scan per request.
        return locationRepository.findAll().filter { location ->
            haversineKm(latitude, longitude, location.latitude, location.longitude) <= radiusInKm
        }
    }

    private fun haversineKm(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Double {
        val earthRadiusKm = 6371.0
        val dLat = Math.toRadians(lat2 - lat1)
        val dLon = Math.toRadians(lon2 - lon1)
        val a = sin(dLat / 2) * sin(dLat / 2) +
            cos(Math.toRadians(lat1)) * cos(Math.toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        return earthRadiusKm * c
    }
}
