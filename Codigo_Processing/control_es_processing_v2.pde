/*
  Interfaz grafica de control de E/S para Arduino (Processing)

  - Panel "ENTRADAS": las teclas r, a, v actuan como pulsadores.
    El casillero se pone de color mientras la tecla esta apretada.
  - Panel "SALIDAS": estado de los LEDs rojo, amarillo y verde.
    Cada pulsacion de tecla conmuta el LED correspondiente (lo hace el
    Arduino). Tambien se puede conmutar con clic del mouse.

  Hay que hacer clic una vez dentro de la ventana para que reciba el teclado.
*/
//DEBUG = true;
import processing.serial.*;

// ---------- Configuracion ----------
final int BAUDIOS = 9600;
int INDICE_PUERTO = -1;      // -1 = ultimo puerto de la lista
final boolean DEBUG = false; // true = imprime en consola lo que se envia/recibe

final int N = 3;
final char[] TECLAS = {'r', 'a', 'v'};
final String[] ETIQ_ENT = {"Tecla R", "Tecla A", "Tecla V"};
final String[] ETIQ_SAL = {"Rojo (pin 8)", "Amarillo (pin 9)", "Verde (pin 10)"};
color[] COLORES = {#F03C32, #FAC81E, #28BE46};

// ---------- Estado ----------
Serial puerto;
boolean[] entradas = new boolean[N];
boolean[] salidas  = new boolean[N];
boolean[] teclaApretada = new boolean[N];   // para ignorar el auto-repeat
boolean conectado = false;
String mensajeEstado = "Buscando Arduino...";
int ultimoPedido = 0;

// ---------- Geometria (salidas debajo de las entradas) ----------
final int TAM = 80;
final int SEP = 25;
final int X_PANEL = 175;   // (640 - (3*80 + 2*25)) / 2
final int Y_ENT = 120;
final int Y_SAL = 300;

void setup() {
  size(640, 520);
  textAlign(CENTER, CENTER);
  surface.setTitle("Control de E/S - Arduino");

  String[] lista = Serial.list();
  println("Puertos disponibles:");
  printArray(lista);

  if (lista.length == 0) {
    mensajeEstado = "No hay puertos serie disponibles";
    return;
  }
  int idx = (INDICE_PUERTO < 0 || INDICE_PUERTO >= lista.length) ? lista.length - 1 : INDICE_PUERTO;
  try {
    puerto = new Serial(this, lista[idx], BAUDIOS);
    puerto.bufferUntil('\n');
    mensajeEstado = "Conectando a " + lista[idx] + "...";
  } catch (Exception e) {
    mensajeEstado = "No se pudo abrir " + lista[idx];
    println(e);
  }
}

void draw() {
  background(245);

  // Al abrir el puerto el Arduino se reinicia: se pide el estado cada
  // segundo hasta recibir la primera respuesta.
  if (puerto != null && !conectado && millis() > 2000 && millis() - ultimoPedido > 1000) {
    puerto.write("?\n");
    ultimoPedido = millis();
  }

  fill(30);
  textSize(22);
  text("Control de Entradas / Salidas - Arduino", width / 2, 35);

  textSize(13);
  fill(conectado ? color(0, 140, 60) : color(180, 60, 0));
  text(conectado ? "Conectado" : mensajeEstado, width / 2, 65);

  dibujarPanel("ENTRADAS (teclado)", Y_ENT, entradas, ETIQ_ENT, false);
  dibujarPanel("SALIDAS (LEDs)", Y_SAL, salidas, ETIQ_SAL, true);

  fill(90);
  textSize(12);
  text("Teclas R / A / V: conmutan el LED rojo / amarillo / verde", width / 2, height - 50);
  text("Tambien se puede conmutar con clic sobre el casillero de salida", width / 2, height - 30);
}

void dibujarPanel(String titulo, int y0, boolean[] estado, String[] etiquetas, boolean clicable) {
  fill(30);
  textSize(18);
  text(titulo, width / 2, y0 - 30);

  for (int i = 0; i < N; i++) {
    int x = X_PANEL + i * (TAM + SEP);
    boolean encima = clicable && sobreCasillero(x, y0);

    stroke(60);
    strokeWeight(encima ? 3 : 1.5);
    fill(estado[i] ? COLORES[i] : color(190));
    rect(x, y0, TAM, TAM, 10);

    noStroke();
    fill(estado[i] ? 20 : 80);
    textSize(20);
    text(estado[i] ? "1" : "0", x + TAM / 2, y0 + TAM / 2 - 8);
    textSize(11);
    text(estado[i] ? "ALTO" : "BAJO", x + TAM / 2, y0 + TAM / 2 + 14);

    fill(40);
    textSize(12);
    text(etiquetas[i], x + TAM / 2, y0 + TAM + 18);
  }
  strokeWeight(1);
}

boolean sobreCasillero(int x, int y) {
  return mouseX >= x && mouseX <= x + TAM && mouseY >= y && mouseY <= y + TAM;
}

// ---------- Mouse: conmuta la salida ----------
void mousePressed() {
  for (int i = 0; i < N; i++) {
    int x = X_PANEL + i * (TAM + SEP);
    if (sobreCasillero(x, Y_SAL)) {
      salidas[i] = !salidas[i];
      enviarSalidas();
    }
  }
}

// ---------- Teclado: actua como pulsador ----------
void keyPressed()  { 
    char k = Character.toLowerCase(key);
    for (int i = 0; i < N; i++) {
      if (k == TECLAS[i] && !teclaApretada[i]) {
        teclaApretada[i] = true;
        entradas[i] = !entradas[i];   // el casillero queda marcado / se desmarca
        enviarPulso(i);               // el Arduino conmuta el LED
      }
    }  
}

void keyReleased() {
  char k = Character.toLowerCase(key);
  for (int i = 0; i < N; i++) {
    if (k == TECLAS[i]) teclaApretada[i] = false;
  }
}

void cambiarTecla(char k, boolean estado) {
  k = Character.toLowerCase(k);
  for (int i = 0; i < N; i++) {
    if (k == TECLAS[i] && entradas[i] != estado) {  // ignora el auto-repeat
      entradas[i] = estado;
      enviarEntradas();
    }
  }
}

// ---------- Envio ----------
void enviarEntradas() {
  if (puerto == null) return;
  String msg = "E";
  for (int i = 0; i < N; i++) msg += entradas[i] ? "1" : "0";
  if (DEBUG) println("Enviado: " + msg);
  puerto.write(msg + "\n");
}

void enviarPulso(int i) {
  if (puerto == null) return;
  String subida = "E";
  String bajada = "E";
  for (int j = 0; j < N; j++) {
    subida += (j == i) ? "1" : "0";
    bajada += "0";
  }
  puerto.write(subida + "\n");   // tecla apretada -> el Arduino conmuta el LED
  puerto.write(bajada + "\n");   // tecla suelta
}

void enviarSalidas() {
  if (puerto == null) return;
  String msg = "S";
  for (int i = 0; i < N; i++) msg += salidas[i] ? "1" : "0";
  if (DEBUG) println("Enviado: " + msg);
  puerto.write(msg + "\n");
}

// ---------- Recepcion ----------
void serialEvent(Serial p) {
  String s = p.readStringUntil('\n');
  if (s == null) return;
  s = trim(s);
  if (DEBUG) println("Recibido: [" + s + "] largo=" + s.length());
  if (s.length() != N + 1) return;

  char tipo = s.charAt(0);
  if (tipo != 'E' && tipo != 'S') return;

  /*for (int i = 0; i < N; i++) {
    boolean v = s.charAt(i + 1) == '1';
    if (tipo == 'E') entradas[i] = v;
    else salidas[i] = v;
  }
  conectado = true;*/
  
  for (int i = 0; i < N; i++) {
    boolean v = s.charAt(i + 1) == '1';
    if (tipo == 'S') salidas[i] = v;   // las 'E' del Arduino se ignoran: el panel de entradas es local
  }
  conectado = true;
}
