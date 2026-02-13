import tensorflow as tf
import numpy as np
from tensorflow.keras.utils import load_img, img_to_array

# CAMINHOS
CAMINHO_MODELO = "modelo_soja.tflite"
CAMINHO_IMAGEM = "teste_google.jpg" # Salve a foto que você baixou com esse nome na pasta

# 1. Carregar o TFLite (Simulando o celular)
interpreter = tf.lite.Interpreter(model_path=CAMINHO_MODELO)
interpreter.allocate_tensors()

input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()

print(f"\nEsperado pelo modelo: {input_details[0]['shape']}")
print(f"Tipo de dados esperado: {input_details[0]['dtype']}")

# 2. Preparar a imagem (Exatamente como o Flutter deveria fazer)
img = load_img(CAMINHO_IMAGEM, target_size=(224, 224))
img_array = img_to_array(img)

# ATENÇÃO: Se no treino usamos Rescaling(1./255) DENTRO do modelo, 
# aqui mandamos a imagem crua (0-255). O modelo se vira.
input_data = np.expand_dims(img_array, axis=0) 

# 3. Rodar a inferência
interpreter.set_tensor(input_details[0]['index'], input_data)
interpreter.invoke()

# 4. Pegar o resultado
output_data = interpreter.get_tensor(output_details[0]['index'])
classes = ['Ferrugem', 'Saudavel'] # Ordem alfabética do seu treino

print("\n--- RESULTADO DO TFLITE NO PC ---")
print(f"Bruto: {output_data[0]}")
index_vencedor = np.argmax(output_data[0])
print(f"Veredito: {classes[index_vencedor].upper()}")
print(f"Confiança: {output_data[0][index_vencedor]*100:.2f}%")