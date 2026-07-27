package com.persons.finder.presentation

import com.persons.finder.data.Location
import com.persons.finder.data.Person
import com.persons.finder.domain.services.LocationsService
import com.persons.finder.domain.services.PersonsService
import com.persons.finder.presentation.dto.CreatePersonRequest
import com.persons.finder.presentation.dto.CreatePersonResponse
import com.persons.finder.presentation.dto.PersonResponse
import com.persons.finder.presentation.dto.UpdateLocationRequest
import org.springframework.http.HttpStatus
import org.springframework.http.ResponseEntity
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.PutMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
@RequestMapping("api/v1/persons")
class PersonController(
    private val personsService: PersonsService,
    private val locationsService: LocationsService
) {

    // POST API to create a 'person'; returns the id of the created entity.
    @PostMapping("")
    fun createPerson(@RequestBody request: CreatePersonRequest): ResponseEntity<CreatePersonResponse> {
        val saved = personsService.save(Person(name = request.name))
        return ResponseEntity.status(HttpStatus.CREATED).body(CreatePersonResponse(saved.id))
    }

    // PUT API to update/create someone's location using latitude and longitude.
    @PutMapping("/location")
    fun updateLocation(@RequestBody request: UpdateLocationRequest): ResponseEntity<Void> {
        locationsService.addLocation(
            Location(
                referenceId = request.id,
                latitude = request.latitude,
                longitude = request.longitude
            )
        )
        return ResponseEntity.ok().build()
    }

    // GET API to retrieve people around a query location, within a radius in KM.
    // Returns just a list of person ids.
    // Example: John (id=1) wants to know who is within 10km of him ->
    //   GET /api/v1/persons/around?id=1&radiusKm=10
    @GetMapping("/around")
    fun findAround(
        @RequestParam id: Long,
        @RequestParam radiusKm: Double
    ): ResponseEntity<List<Long>> {
        val origin = personsService.getById(id)
        val originLocation = locationsService.getLocation(origin.id)
            ?: return ResponseEntity.ok(emptyList())

        val nearby = locationsService.findAround(originLocation.latitude, originLocation.longitude, radiusKm)
            .filter { it.referenceId != origin.id }
            .map { it.referenceId }

        return ResponseEntity.ok(nearby)
    }

    // GET API to retrieve a person or persons' names using their ids.
    // Example: GET /api/v1/persons?ids=1,2,3
    @GetMapping("")
    fun getByIds(@RequestParam ids: List<Long>): ResponseEntity<List<PersonResponse>> {
        val people = personsService.getByIds(ids).map { PersonResponse(it.id, it.name) }
        return ResponseEntity.ok(people)
    }
}
