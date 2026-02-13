import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.applications import MobileNetV2
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D, Dropout, Input
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
import os

# --- CONFIGURAÇÕES ---
caminho_dataset = r"C:\Users\User\Desktop\AGdata\inteligencia\dataset"
TAMANHO_IMG = 224
BATCH_SIZE = 32
EPOCHS_INICIAIS = 10  # Treino rápido da "cabeça" nova
EPOCHS_FINETUNING = 10 # Treino lento para refinar o "cérebro"

print("========================================")
print(f"Versão do TensorFlow: {tf.__version__}")
print(f"GPU Disponível: {len(tf.config.list_physical_devices('GPU')) > 0}")

# --- PREPARAÇÃO DAS IMAGENS ---
# Mantivemos rescale=1./255 para facilitar sua vida no Flutter
train_datagen = ImageDataGenerator(
    rescale=1./255,
    rotation_range=40,
    width_shift_range=0.2,
    height_shift_range=0.2,
    shear_range=0.2,
    zoom_range=0.2,
    horizontal_flip=True,
    fill_mode='nearest',
    validation_split=0.2
)

print("\n--- Carregando Dataset ---")
train_generator = train_datagen.flow_from_directory(
    caminho_dataset,
    target_size=(TAMANHO_IMG, TAMANHO_IMG),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='training',
    shuffle=True
)

validation_generator = train_datagen.flow_from_directory(
    caminho_dataset,
    target_size=(TAMANHO_IMG, TAMANHO_IMG),
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    subset='validation'
)

# Verifica se achou as classes certas
class_names = list(train_generator.class_indices.keys())
print(f"Classes detectadas: {class_names}")
if len(class_names) != 2:
    print("ERRO CRÍTICO: O dataset precisa ter exatamente 2 pastas (ferrugem e saudavel). Verifique suas pastas!")
    exit()

# --- FASE 1: TRANSFER LEARNING (CONGELADO) ---
print("\n--- Construindo MobileNetV2 ---")
# Carrega a MobileNetV2 sem a parte de classificação (include_top=False)
base_model = MobileNetV2(weights='imagenet', include_top=False, input_shape=(TAMANHO_IMG, TAMANHO_IMG, 3))

# Congela a base para não destruir o que ela já sabe
base_model.trainable = False

# Cria a nova cabeça para Soja
inputs = Input(shape=(TAMANHO_IMG, TAMANHO_IMG, 3))
x = base_model(inputs, training=False)
x = GlobalAveragePooling2D()(x)
x = Dropout(0.2)(x)  # Evita overfitting
outputs = Dense(2, activation='softmax')(x)

model = Model(inputs, outputs)

model.compile(optimizer=Adam(learning_rate=0.001),
              loss='categorical_crossentropy',
              metrics=['accuracy'])

print("\n--- Fase 1: Treinando apenas a classificação ---")
history = model.fit(
    train_generator,
    epochs=EPOCHS_INICIAIS,
    validation_data=validation_generator
)

# --- FASE 2: FINE TUNING (DESCONGELAMENTO PARCIAL) ---
print("\n--- Fase 2: Ajuste Fino (Fine Tuning) ---")
# Descongela a base
base_model.trainable = True

# Vamos treinar apenas as últimas 50 camadas da MobileNet (ela tem 155 camadas)
# Isso permite que ela aprenda as texturas específicas da FERRUGEM
fine_tune_at = 100

for layer in base_model.layers[:fine_tune_at]:
    layer.trainable = False

# Compila com taxa de aprendizado MUITO BAIXA para não estragar o modelo
model.compile(optimizer=Adam(learning_rate=1e-5), # 0.00001
              loss='categorical_crossentropy',
              metrics=['accuracy'])

history_fine = model.fit(
    train_generator,
    epochs=EPOCHS_FINETUNING,
    validation_data=validation_generator
)

# --- SALVANDO ---
caminho_modelo = 'modelo_soja.keras'
model.save(caminho_modelo)
print(f"\n✅ SUCESSO! Modelo salvo em: {caminho_modelo}")

# Salva o arquivo de labels
with open("labels.txt", "w") as f:
    for classe in class_names:
        f.write(f"{classe}\n")
print("Arquivo labels.txt atualizado.")