import tensorflow as tf
from tensorflow.keras import layers, models
import os

# CONFIGURAÇÕES
img_height = 224
img_width = 224
batch_size = 32
data_dir = "dataset" 

print("="*40)
print(f"Versão do TensorFlow: {tf.__version__}")
print(f"Procurando imagens em: {os.path.abspath(data_dir)}")

# Verifica se a pasta existe
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
    exit()

class_names = train_ds.class_names
print(f"\nClasses detectadas: {class_names}")

# MELHORANDO A PERFORMANCE
AUTOTUNE = tf.data.AUTOTUNE
train_ds = train_ds.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)

# --- AQUI ESTÁ A MÁGICA (DATA AUGMENTATION) ---
data_augmentation = models.Sequential([
    layers.RandomFlip("horizontal_and_vertical"),
    layers.RandomRotation(0.2), # Gira a imagem em até 20%
    layers.RandomZoom(0.2),     # Zoom de até 20%
    layers.RandomContrast(0.2), # Muda o contraste
    layers.RandomBrightness(0.2), # Muda o brilho
])

# CRIANDO O CÉREBRO (MODELO MAIS ROBUSTO)
model = models.Sequential([
    layers.Input(shape=(img_height, img_width, 3)),
    
    # 1. Aplica as distorções (SÓ NO TREINO)
    data_augmentation,
    
    # 2. Normaliza os pixels (0 a 255 -> 0 a 1)
    layers.Rescaling(1./255),
    
    layers.Conv2D(16, 3, padding='same', activation='relu'),
    layers.MaxPooling2D(),
    layers.Conv2D(32, 3, padding='same', activation='relu'),
    layers.MaxPooling2D(),
    layers.Conv2D(64, 3, padding='same', activation='relu'),
    layers.MaxPooling2D(),
    
    # Camada extra para aprender mais detalhes
    layers.Conv2D(128, 3, padding='same', activation='relu'),
    layers.MaxPooling2D(),
    
    layers.Flatten(),
    
    # DROPOUT: Desliga 50% dos neurônios aleatoriamente para evitar "decoreba"
    layers.Dropout(0.5), 
    
    layers.Dense(128, activation='relu'),
    layers.Dense(len(class_names), activation='softmax')
])

model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])

print("\n--- Iniciando Treinamento ROBUSTO ---")
# Aumentei para 25 épocas porque agora o treino é mais difícil (o que é bom!)
epochs = 25 
history = model.fit(
  train_ds,
  validation_data=val_ds,
  epochs=epochs
)

# SALVAR
model.save('modelo_soja.h5')
print("\n✅ SUCESSO! Modelo novo salvo.")