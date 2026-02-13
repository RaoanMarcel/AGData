import tensorflow as tf

print("Carregando o modelo .keras...")

model = tf.keras.models.load_model('modelo_soja.keras')

converter = tf.lite.TFLiteConverter.from_keras_model(model)


print("Convertendo para TFLite (modo compatibilidade)...")
tflite_model = converter.convert()

with open('modelo_soja.tflite', 'wb') as f:
    f.write(tflite_model)

print("SUCESSO! Novo arquivo 'modelo_soja.tflite' gerado.")