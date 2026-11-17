Circuito de LEDS con Arduino:
<img width="1600" height="900" alt="a35a3aa1-c4cd-499a-8cad-31d5a0753021" src="https://github.com/user-attachments/assets/2f843924-77e3-4bb5-aa7f-339f6ce0a6dc" />
Conectar la pata más corta (terminal negativa del LED) de cada LED a tierra y conectar con un jumper la tierra de la Protoboard a algún GND de la placa Arduino en la sección "Power".
Luego conectar en serie a la pata más larga (terminal positiva) una resistencia de 220 ohm (idealmente, cualquier valor superior al mencionado es válido, en mi caso utilicé 3,3 kOhm). Conectar en serie a la resistencia un jumper al pin digital de su preferencia. Hacer esto en cada LED (en mi caso los pines 8,9 y 10).

Por último verificar el código .ino presente en la carpeta con Arduino IDE. Seleccionar el puerto disponible que esté por debajo de COM1 (puede llamarse COM4, COM5 o COM6 según el caso), asignarle la placa Arduino a utilizar, en este caso yo utilicé una placa Arduino UNO. Y finalmente cargar el programa a la placa.
Todo como se indica en la siguiente imagen.
<img width="741" height="590" alt="Image 4" src="https://github.com/user-attachments/assets/c75345fb-b94e-49eb-b381-f76551169d7f" />

Es fundamental tener el programa cargado y el Arduino conectado previamente para poder hacer uso de la interfaz en Processing. Que se indica como utilizarla en el README de la carpeta "Codigo_Processing".



