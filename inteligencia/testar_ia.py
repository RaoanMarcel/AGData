import tensorflow as tf
import numpy as np
import os

# Importação moderna (Resolve o erro do Pylance)
from tensorflow.keras.utils import load_img, img_to_array

# Carrega o modelo treinado
print("Carregando o cérebro da IA...")
model = tf.keras.models.load_model('modelo_soja.h5')

# Defina as classes manualmente na mesma ordem alfabética das pastas
class_names = ['ferrugem', 'saudavel'] 

def testar_imagem(caminho_imagem):
    if not os.path.exists(caminho_imagem):
        print(f"Erro: Imagem {caminho_imagem} não encontrada.")
        return

    # Prepara a imagem (mesmo tamanho do treino)
    img = load_img(caminho_imagem, target_size=(224, 224))
    img_array = img_to_array(img)
    img_array = tf.expand_dims(img_array, 0) # Cria um lote de 1 imagem

    # Faz a previsão
    predictions = model.predict(img_array)
    score = tf.nn.softmax(predictions[0])

    print(f"\nResultado para {caminho_imagem}:")
    print(f"Eu acho que é: {class_names[np.argmax(score)]}")
    print(f"Certeza: {100 * np.max(score):.2f}%")

testar_imagem('teste.jpg') 
print("Modelo carregado com sucesso. Edite o arquivo para testar uma imagem específica.")