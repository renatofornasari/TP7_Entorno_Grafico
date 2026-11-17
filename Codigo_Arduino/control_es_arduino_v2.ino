/*
  Control de LEDs desde Processing (teclas r, a, v) - Arduino

  LEDs (con resistencia de 220 ohm a GND):
    Rojo     -> pin 8
    Amarillo -> pin 9
    Verde    -> pin 10

  Protocolo serie (9600 baudios, texto, cada mensaje termina en '\n'):
    Arduino -> PC:  "E100\n"  estado de las "teclas" (1 = apretada)
                    "S010\n"  estado de los LEDs     (1 = encendido)
    PC -> Arduino:  "E100\n"  estado de las teclas (la PC detecta el teclado)
                    "S101\n"  poner los LEDs en ese estado (clic del mouse)
                    "?\n"     pedir el estado actual

  Cada vez que una tecla pasa de suelta a apretada, el LED CONMUTA:
  si estaba apagado se enciende, y si estaba encendido se apaga.
*/

const byte N = 3;
const byte pinSalida[N] = {8, 9, 10};   // rojo, amarillo, verde

bool estadoEntrada[N];
bool estadoSalida[N];

char buffer[16];
byte pos = 0;

void setup() {
  Serial.begin(9600);
  for (byte i = 0; i < N; i++) {
    pinMode(pinSalida[i], OUTPUT);
    digitalWrite(pinSalida[i], LOW);
    estadoEntrada[i] = false;
    estadoSalida[i] = false;
  }
}

void loop() {
  revisarSerie();
}

void aplicarSalidas() {
  for (byte i = 0; i < N; i++) {
    digitalWrite(pinSalida[i], estadoSalida[i] ? HIGH : LOW);
  }
}

void enviarEntradas() {
  Serial.print('E');
  for (byte i = 0; i < N; i++) Serial.print(estadoEntrada[i] ? '1' : '0');
  Serial.println();
}

void enviarSalidas() {
  Serial.print('S');
  for (byte i = 0; i < N; i++) Serial.print(estadoSalida[i] ? '1' : '0');
  Serial.println();
}

// Arma la linea recibida byte a byte y la procesa al llegar el fin de linea.
void revisarSerie() {
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') {
      if (pos > 0) {
        buffer[pos] = '\0';
        procesarComando();
        pos = 0;
      }
    } else if (pos < sizeof(buffer) - 1) {
      buffer[pos++] = c;
    }
  }
}

void procesarComando() {
  if (buffer[0] == '?') {
    // La PC pide el estado actual
    enviarEntradas();
    enviarSalidas();

  } else if (buffer[0] == 'E' && pos == N + 1) {
    // La PC informa el estado de las teclas
    for (byte i = 0; i < N; i++) {
      bool nuevo = (buffer[i + 1] == '1');
      if (nuevo && !estadoEntrada[i]) {
        estadoSalida[i] = !estadoSalida[i];   // flanco de subida: conmutar
      }
      estadoEntrada[i] = nuevo;
    }
    aplicarSalidas();
    enviarEntradas();
    enviarSalidas();

  } else if (buffer[0] == 'S' && pos == N + 1) {
    // La PC pide un estado concreto de LEDs (clic del mouse)
    for (byte i = 0; i < N; i++) {
      estadoSalida[i] = (buffer[i + 1] == '1');
    }
    aplicarSalidas();
    enviarSalidas();
  }
}
