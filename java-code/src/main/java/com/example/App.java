package com.example;

import com.google.gson.Gson;
import gnu.crypto.Registry;

public class App {
    public static void main(String[] args) {
        Person person = new Person("Alice", 30);
        Gson gson = new Gson();
        String json = gson.toJson(person);
        System.out.println("JSON Output: " + json);

        String dummy = Registry.AES_CIPHER;
        if (dummy != null) {
            System.out.println("GPL library referenced: " + dummy);
        }
    }

    static class Person {
        String name;
        int age;

        Person(String name, int age) {
            this.name = name;
            this.age = age;
        }
    }
}
