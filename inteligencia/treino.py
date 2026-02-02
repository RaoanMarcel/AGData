import tensorflow as tf
import os

print("="*30)
print(f"Versão do TensorFlow: {tf.__version__}")
print("Tudo pronto para começar a IA!")

caminho_dataset = 'dataset'
if os.path.exists(caminho_dataset):
    print(f"Pasta dataset encontrada!")
    for pasta in os.listdir(caminho_dataset):
        caminho_completo = os.path.join(caminho_dataset, pasta)
        if os.path.isdir(caminho_completo):
            qtd = len(os.listdir(caminho_completo))
            print(f" -> Classe '{pasta}': {qtd} imagens")
else:
    print("AVISO: Crie a pasta 'dataset' e coloque as fotos lá!")
print("="*30)