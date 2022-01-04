Database design proof of concept work for tying patient demographics to activities. The goal of this POC is to provide a design that allows demographic updates to flow to activities while minimizing required DB updates, and maintaining a traceable history of said updates. 

Scenarios covered:
1. Updated patient demographics reflecting real time in activities
2. Creating new demographics and assigning them to activities
3. Merging patient demographics in the scenario of incorrectly chosen patients
4. Deactivating identities and reflecting the deactivation across application
5. Saving an activity and "locking in" the demographics at time of save

This project's frontend has been written in Flutter/Dart, the REST backend in Kotlin with SpringBoot, and includes a Dockerfile containing a Postgres DB image.
