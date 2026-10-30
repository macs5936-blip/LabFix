# reportes_labs_espoch

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase

La app incluye servicios iniciales para Firebase Authentication y Cloud Firestore.

### Configuración

1. Crea un proyecto en [Firebase Console](https://console.firebase.google.com/) y registra una app por cada plataforma que vayas a ejecutar.
2. En Authentication, habilita el proveedor **Correo electrónico/Contraseña**.
3. En Firestore Database, crea una base de datos en modo producción.
4. Copia los valores de configuración de la app Firebase y ejecuta Flutter pasando los valores. El `appId` debe ser el de la plataforma seleccionada:

```powershell
flutter run --dart-define=FIREBASE_API_KEY=... --dart-define=FIREBASE_APP_ID=... --dart-define=FIREBASE_MESSAGING_SENDER_ID=... --dart-define=FIREBASE_PROJECT_ID=... --dart-define=FIREBASE_AUTH_DOMAIN=your-project-id.firebaseapp.com
```

`FIREBASE_AUTH_DOMAIN` es opcional y se usa principalmente en web. Sin los valores requeridos, Firebase no se inicializa y la pantalla de acceso conserva su modo de demostración. Las claves de configuración del cliente identifican el proyecto, pero no sustituyen las reglas de seguridad. Nunca incluyas una clave de cuenta de servicio en Flutter.

### Publicar reglas

Instala Firebase CLI, inicia sesión y selecciona el proyecto:

```powershell
firebase login
firebase use --add
firebase deploy --only firestore
```

Las reglas están en `firestore.rules` y los índices compuestos en `firestore.indexes.json`. El alta pública solo crea perfiles con rol `student`; la promoción a `technician` o `admin` debe hacerse desde un entorno confiable con Firebase Admin SDK, nunca desde la app cliente.

### Esquema de Firestore

- `users/{uid}`: `uid`, `displayName`, `email`, `role` (`student`, `technician`, `admin`) y `createdAt`.
- `labs/{labId}`: `name`, `building`, `location`, `capacity`, `technicianId`, `notes`, `active`, `createdAt` y `updatedAt`.
- `reports/{reportId}`: `createdBy`, `createdByName`, `building`, `laboratory`, `machine`, `category`, `hasEvidence`, `urgency` (`baja`, `media`, `alta`), `description`, `status` (`pendiente`, `enAtencion`, `resuelto`), `technicianId`, `createdAt` y `updatedAt`.
- `reports/{reportId}/messages/{messageId}`: `authorId`, `authorName`, `body` y `sentAt`.

Los servicios están en `lib/data/auth_service.dart`, `lib/data/lab_service.dart` y `lib/data/report_service.dart`. El inicio de sesión y los formularios actuales aún usan el flujo de demostración; la conexión de esas pantallas es el siguiente paso de integración.
