import tensorflow as tf

print("Carregando o modelo .h5...")
model = tf.keras.models.load_model('modelo_soja.h5')

# Iniciando o conversor
converter = tf.lite.TFLiteConverter.from_keras_model(model)

# Otimizações para celular (deixa o arquivo mais leve)
converter.optimizations = [tf.lite.Optimize.DEFAULT]

print("Convertendo para TFLite (isso pode travar um pouco)...")
tflite_model = converter.convert()

# Salvando o arquivo final
with open('modelo_soja.tflite', 'wb') as f:
    f.write(tflite_model)

print("SUCESSO! Arquivo 'modelo_soja.tflite' gerado.")