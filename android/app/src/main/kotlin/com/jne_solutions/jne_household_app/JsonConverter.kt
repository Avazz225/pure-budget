package com.jne_solutions.jne_household_app

import org.json.JSONArray

fun jsonObjectToMap(obj: org.json.JSONObject): Map<String, Any?> {
    val map = mutableMapOf<String, Any?>()
    val keys = obj.keys()
    while (keys.hasNext()) {
        val key = keys.next()
        val value = obj.get(key)
        map[key] = when (value) {
            is JSONArray -> jsonArrayToList(value)
            is org.json.JSONObject -> jsonObjectToMap(value)
            else -> value
        }
    }
    return map
}

fun jsonArrayToList(array: JSONArray): List<Any?> {
    val list = mutableListOf<Any?>()
    for (i in 0 until array.length()) {
        when (val value = array.get(i)) {
            is JSONArray -> list.add(jsonArrayToList(value))
            is org.json.JSONObject -> list.add(jsonObjectToMap(value))
            else -> list.add(value)
        }
    }
    return list
}

inline fun <reified T> parseJsonList(
    json: String,
    crossinline mapper: (Map<String, Any?>) -> T
): List<T> {
    val array = JSONArray(json)
    val rawList = jsonArrayToList(array)
    return rawList.map { mapper(it as Map<String, Any?>) }
}