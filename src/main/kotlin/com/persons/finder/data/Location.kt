package com.persons.finder.data

import javax.persistence.Entity
import javax.persistence.Id

@Entity
data class Location(
    // Person's id is reused as the primary key: one location row per person.
    @Id
    val referenceId: Long = 0,
    val latitude: Double = 0.0,
    val longitude: Double = 0.0
)
