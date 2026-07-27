package com.persons.finder.domain.services

import com.persons.finder.data.Person
import com.persons.finder.data.repositories.PersonRepository
import org.springframework.stereotype.Service
import javax.persistence.EntityNotFoundException

@Service
class PersonsServiceImpl(
    private val personRepository: PersonRepository
) : PersonsService {

    override fun getById(id: Long): Person {
        return personRepository.findById(id)
            .orElseThrow { EntityNotFoundException("Person with id $id not found") }
    }

    override fun getByIds(ids: List<Long>): List<Person> {
        return personRepository.findAllById(ids)
    }

    override fun save(person: Person): Person {
        return personRepository.save(person)
    }
}
