// Retira la pantalla de carga en cuanto Flutter pinta su primera vista.
//
// Vive en un archivo aparte, y no como <script> en el index, para que la
// Content-Security-Policy no necesite 'unsafe-inline' en script-src: con
// scripts en linea permitidos, una inyeccion de HTML podria ejecutar codigo.
window.addEventListener('flutter-first-frame', function () {
  var splash = document.getElementById('readeriz-loading');
  if (splash) splash.remove();
});
