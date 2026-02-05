import tensorflow as tf
from tensorflow.keras import layers, models
import os

# CONFIGURAÇÕES
img_height = 224
img_width = 224
batch_size = 32
data_dir = "dataset" # Sua pasta com as imagens

print("="*40)
print(f"Versão do TensorFlow: {tf.__version__}")
print(f"Procurando imagens em: {os.path.abspath(data_dir)}")

# Verifica se a pasta existe antes de começar
if not os.path.exists(data_dir):
    print(f"ERRO: A pasta '{data_dir}' não foi encontrada!")
    exit()

# CARREGAMENTO DAS IMAGENS
print("\n--- Carregando Dataset ---")
try:
    train_ds = tf.keras.utils.image_dataset_from_directory(
        data_dir,
        validation_split=0.2,
        subset="training",
        seed=123,
        image_size=(img_height, img_width),
        batch_size=batch_size
    )

    val_ds = tf.keras.utils.image_dataset_from_directory(
        data_dir,
        validation_split=0.2,
        subset="validation",
        seed=123,
        image_size=(img_height, img_width),
        batch_size=batch_size
    )
except ValueError as e:
    print("\nERRO CRÍTICO: Não encontrei imagens suficientes nas pastas.")
    print("Certifique-se que dentro de 'dataset' existem as pastas 'ferrugem' e 'saudavel'")
    exit()

class_names = train_ds.class_names
print(f"\nClasses detectadas: {class_names}")

# MELHORANDO A PERFORMANCE (Cache)
AUTOTUNE = tf.data.AUTOTUNE
train_ds = train_ds.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)

# CRIANDO O CÉREBRO (MODELO)
model = models.Sequential([
  layers.Rescaling(1./255, input_shape=(img_height, img_width, 3)),
  layers.Conv2D(16, 3, padding='same', activation='relu'),
  layers.MaxPooling2D(),
  layers.Conv2D(32, 3, padding='same', activation='relu'),
  layers.MaxPooling2D(),
  layers.Conv2D(64, 3, padding='same', activation='relu'),
  layers.MaxPooling2D(),
  layers.Flatten(),
  layers.Dense(128, activation='relu'),
  layers.Dense(len(class_names), activation='softmax')
])

model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])

print("\n--- Iniciando Treinamento ---")
epochs = 10 
history = model.fit(
  train_ds,
  validation_data=val_ds,
  epochs=epochs
)

# SALVAR
model.save('modelo_soja.h5')
print("\n✅ SUCESSO! Modelo salvo como 'modelo_soja.h5'")