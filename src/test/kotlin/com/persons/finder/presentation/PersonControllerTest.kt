package com.persons.finder.presentation

import com.fasterxml.jackson.databind.ObjectMapper
import com.persons.finder.data.Location
import com.persons.finder.data.Person
import com.persons.finder.domain.services.LocationsService
import com.persons.finder.domain.services.PersonsService
import com.persons.finder.presentation.dto.CreatePersonRequest
import com.persons.finder.presentation.dto.UpdateLocationRequest
import com.ninjasquad.springmockk.MockkBean
import io.mockk.every
import io.mockk.just
import io.mockk.runs
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest
import org.springframework.http.MediaType
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.*

@WebMvcTest(PersonController::class)
class PersonControllerTest {

    @Autowired
    lateinit var mockMvc: MockMvc

    @Autowired
    lateinit var objectMapper: ObjectMapper

    @MockkBean
    lateinit var personsService: PersonsService

    @MockkBean
    lateinit var locationsService: LocationsService

    @Test
    fun `create person returns 201 with the new id`() {
        every { personsService.save(any()) } returns Person(id = 42, name = "John")

        mockMvc.perform(
            post("/api/v1/persons")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(CreatePersonRequest("John")))
        )
            .andExpect(status().isCreated)
            .andExpect(jsonPath("$.id").value(42L))
    }

    @Test
    fun `update location returns 200`() {
        every { locationsService.addLocation(any()) } just runs

        mockMvc.perform(
            put("/api/v1/persons/location")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(UpdateLocationRequest(1, -36.8485, 174.7633)))
        )
            .andExpect(status().isOk)
    }

    @Test
    fun `find around returns nearby person ids excluding self`() {
        every { personsService.getById(1) } returns Person(id = 1, name = "John")
        every { locationsService.getLocation(1) } returns Location(1, -36.8485, 174.7633)
        every { locationsService.findAround(-36.8485, 174.7633, 10.0) } returns listOf(
            Location(1, -36.8485, 174.7633),
            Location(3, -36.8330, 174.7970)
        )

        mockMvc.perform(get("/api/v1/persons/around").param("id", "1").param("radiusKm", "10"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$[0]").value(3))
    }

    @Test
    fun `get by ids returns names`() {
        every { personsService.getByIds(listOf(1, 2)) } returns listOf(
            Person(1, "John"),
            Person(2, "Jane")
        )

        mockMvc.perform(get("/api/v1/persons").param("ids", "1,2"))
            .andExpect(status().isOk)
            .andExpect(jsonPath("$[0].name").value("John"))
            .andExpect(jsonPath("$[1].name").value("Jane"))
    }
}
