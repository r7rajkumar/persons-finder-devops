import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

plugins {
	id("org.springframework.boot") version "2.7.18"
	id("io.spring.dependency-management") version "1.0.11.RELEASE"
	kotlin("jvm") version "1.6.21"
	kotlin("plugin.spring") version "1.6.21"
	kotlin("plugin.jpa") version "1.6.21"
}

group = "com.persons.finder"
version = "0.0.1-SNAPSHOT"
java.sourceCompatibility = JavaVersion.VERSION_11

repositories {
	mavenCentral()
}

// Override vulnerable transitive dependencies pulled in by Spring Boot 2.7.18.
// Spring Boot's dependency management sets these versions; we override them
// explicitly here to get the patched versions without upgrading to Spring Boot 3.
// Override vulnerable transitive dependencies pulled in by Spring Boot 2.7.18.
// Spring Boot's dependency management sets these versions; we override them
// explicitly here to get the patched versions without upgrading to Spring Boot 3.
// Note: jackson-bom cannot be upgraded past 2.15.x with Kotlin 1.6 —
// jackson-module-kotlin 2.16+ requires Kotlin 1.8+.
ext["tomcat.version"]        = "9.0.118"  // fixes all Tomcat CVEs
ext["h2.version"]            = "2.2.220"  // fixes CVE-2022-45868
ext["logback.version"]       = "1.2.13"  // fixes CVE-2023-6378, CVE-2023-6481
ext["snakeyaml.version"]     = "2.0"     // fixes CVE-2022-1471, CVE-2022-25857

dependencies {
	implementation("org.springframework.boot:spring-boot-starter")
	implementation("org.springframework.boot:spring-boot-starter-data-jpa")
	implementation("org.springframework.boot:spring-boot-starter-web")
	implementation("org.springframework.boot:spring-boot-starter-actuator")
	implementation("com.h2database:h2")
	implementation("org.jetbrains.kotlin:kotlin-reflect")
	implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
	testImplementation("org.springframework.boot:spring-boot-starter-test")
	testImplementation("io.mockk:mockk:1.13.5")
	testImplementation("com.ninja-squad:springmockk:3.1.1")
}

tasks.withType<KotlinCompile> {
	kotlinOptions {
		freeCompilerArgs = listOf("-Xjsr305=strict")
		jvmTarget = "11"
	}
}

tasks.withType<Test> {
	useJUnitPlatform()
}
