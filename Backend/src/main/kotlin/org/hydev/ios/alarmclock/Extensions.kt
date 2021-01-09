package org.hydev.ios.alarmclock

import org.springframework.http.ResponseEntity
import java.security.SecureRandom
import javax.crypto.SecretKeyFactory

import javax.crypto.spec.PBEKeySpec

import java.security.spec.KeySpec
import java.util.*

/**
 * Generate "Bad Request" response entity
 *
 * @param msg Message
 * @return Response entity
 */
fun bad(msg: String): ResponseEntity<String> = ResponseEntity.badRequest().body(msg)

/**
 * Generate random salt
 *
 * @param len Length of the salt in bytes
 * @return Random byte array of size len
 */
fun randSalt(len: Int = 16): ByteArray
{
    val random = SecureRandom()
    val salt = ByteArray(16)
    random.nextBytes(salt)
    return salt
}
