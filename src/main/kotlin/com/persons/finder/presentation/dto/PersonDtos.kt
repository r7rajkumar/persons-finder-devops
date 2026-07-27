package com.persons.finder.presentation.dto

data class CreatePersonRequest(
    val name: String
)

data class CreatePersonResponse(
    val id: Long
)

data class PersonResponse(
    val id: Long,
    val name: String
)

data class UpdateLocationRequest(
    val id: Long,
    val latitude: Double,
    val longitude: Double
)
