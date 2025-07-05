#### 1. Librerías e Importación de Datos  ####
#install.packages("tidyverse")
#install.packages("tidytext")
#install.packages("stopwords")
library(ggplot2)
library(tidyverse)
library(lubridate)
library(dplyr)
library(tidytext)
library(stopwords)

datos <- read_csv("reseñas_audifonos_sinteticas.csv")
View(datos)

#### 2. Exploración Inicial y Limpieza de Datos ####
glimpse(datos)
summary(datos)

is.na(datos)

#### 2.1. Limpieza de Texto ####
texto_limpio <- datos %>%
  mutate(
    texto = texto %>%
      #Convertimos a minúsculas todo el texto
      str_to_lower() %>%
      #Eliminamos caracteres especiales
      str_remove_all("[[:punct:]]") %>%
      str_remove_all("\\d+") %>%
      # Eliminamos URLs, menciones y hashtags
      str_remove_all("https?://\\S+") %>%
      str_remove_all("@\\w+") %>%
      str_remove_all("#\\w+") %>%
      #Eliminamos espacios extra
      str_squish()
  )

#Cambiamos el nombre de la columna "texto" a "comentarios" para que sea más claro.
texto_limpio <- texto_limpio %>%
  rename(comentarios = texto)
  
View(texto_limpio)

#Creamos una nueva columna con la longitud total del comentario
df_limpio <- texto_limpio %>%
  mutate(
    longitud_del_comentario = str_count(texto_limpio$comentarios)
  )
View(df_limpio)

#Con esta limpieza de texto podemos deshacernos de caracteres innecesarios, spam a URLs, etc. Nuestro dataset ahora queda
#mucho más limpio, fácil de identificar, y listo para el siguiente paso.

#### 2.2. Tokenización y Stop Words ####
df_tokens <- df_limpio %>%
  unnest_tokens(output = palabra, input = comentarios)
View(df_tokens)

#Usamos stop words para eliminar las palabras que provean poco o nada de información.
stop_words_es <- data.frame(palabra = stopwords("es"))
View(stop_words_es)

df_filtrado <- df_tokens %>%
  anti_join(stop_words_es, by = "palabra")
View(df_filtrado)

#Con esto eliminamos el ruido, gracias a la tokenización y a la eliminación de stop words.

#### 3. Análisis Exploratorio de Datos  ####
#El siguiente paso será ver la frecuencia que tienen las palabras en nuestros comentarios limpios.

#### 3.1. Contar la Frecuencia  ####
frecuencia <- df_filtrado %>%
  count(palabra, sort = TRUE)
View(frecuencia)
print(sum(frecuencia$n))

#Ahora creamos un gráfico para visualizar fácilmente nuestros nuevos datos.
#Tomo en cuenta que nuestro dataframe tiene un total de 90 palabras, de las cuales 21 de ellas
#se repiten 6 veces o más. Usaré esas 21 palabras para realizar el gráfico.

#### 3.2. Gráfico de Frecuencia ####
frecuencia %>%
  head(21) %>%
  ggplot(aes(x = reorder(palabra, n), y = n)) +
  geom_col() +
  coord_flip() +
  labs(title = "Palabras con Mayor Frecuencia", x = "Palabras", y = "Frecuencia") +
  theme_classic()

#### 3.3. Análisis de Sentimientos Contextual ####
#Cabe destacar que invertí una cantidad de tiempo considerable para encontrar un léxico
#de sentimientos en español con puntuaciones de polaridad.
#Al final encontré un dataframe en GitHub posteado en el 2020.
#https://github.com/jboscomendoza/lexicos-nrc-afinn/blob/master/lexico_afinn.csv

View(lexico_afinn)
glimpse(lexico_afinn)
summary(lexico_afinn)

lexico_sentimiento <- lexico_afinn %>%
  select(palabra, puntuacion)

glimpse(lexico_sentimiento)
View(lexico_sentimiento)

#Uniremos los dos dataframes.
df_con_sentimientos <- df_filtrado %>%
  inner_join(lexico_sentimiento, by = "palabra")

View(df_con_sentimientos)

palabras_encontradas <- df_con_sentimientos %>% 
  distinct(palabra) %>% 
  nrow()

total_palabras_reseñas <- df_filtrado %>% 
  distinct(palabra) %>% 
  nrow()

#### 3.4. Porcentaje de Cobertura ####
print(paste("Palabras de reseñas encontradas en el léxico:", palabras_encontradas))
print(paste("Total de palabras únicas en reseñas filtradas:", total_palabras_reseñas))
print(paste("Porcentaje de cobertura:", round(palabras_encontradas / total_palabras_reseñas * 100, 2), "%"))

#En este caso nos encontramos con un problema de limitación de datos muy importante. El dataframe encontrado en Kaggle
#abarca un 22.22% del total de nuestras palabras en los comentarios luego de la limpieza.
#Esto afecta en demasía la precisión de nuestro análisis. Por ejemplo, la palabra "precio" es la
#que tiene una mayor frecuencia y no se encuentra en el dataframe o "amo" que es la tercera en frecuencia.
#A pesar de que el léxico de sentimientos empleado cubrió aproximadamente solo el 22% de las palabras únicas en las reseñas,
#se decidió proceder con el análisis para ilustrar el flujo de trabajo completo de un proyecto de análisis de sentimientos basado en léxicos.
#Esta aproximación permite demostrar las etapas clave del preprocesamiento, tokenización, aplicación de léxicos y clasificación de sentimientos.
# Para futuros proyectos reales, se priorizaría la integración de léxicos más extensos
#o el uso de modelos de lenguaje avanzados para garantizar una mayor precisión y cobertura contextual.

#### 3.5. Score Total de Cada Reseña  ####
#Calculamos el score total de cada reseña.

sentimiento_por_reseña <- df_con_sentimientos %>%
  group_by(id) %>%                                    #Agrupamos por reseña
  summarise(
    score_total = sum(puntuacion, na.rm = TRUE),      #Sumamos las cantidades agrupadas por id
    num_palabras_con_sentimiento = n()
  ) %>%
  ungroup()

View(sentimiento_por_reseña)

#### 3.6. Clasificación de Sentimientos por Reseña  ####
#Clasificamos los sentimientos de cada reseña.
#Usaremos la escala desde -5 hasta 5, en donde <0 negativo, 0 es neutro, de >0 es positivo.

reseña_clasificada <- sentimiento_por_reseña %>%
  mutate(
    sentimiento_final = case_when(
      score_total > 0 ~ "Positivo",  #Score mayor a 5 será positivo.
      score_total < 0 ~ "Negativo",  #Score menor a 5 será negativo.
      TRUE ~ "Neutro"                #Score de cero será neutro.
    )
  )

View(reseña_clasificada)

#### 3.7. Cálculo de la Distribución de Sentimientos  ####
#Calculamos la distribución de sentimientos.

distribucion_sentimientos <- reseña_clasificada %>%
  count(sentimiento_final) %>%
  mutate(porcentaje = n / sum(n) * 100)

View(distribucion_sentimientos)

#### 3.8. Gráfico de la Distribución de Sentimientos  ####
ggplot(distribucion_sentimientos, aes(x = "", y = porcentaje, fill = sentimiento_final)) +
  geom_bar(width = 1, stat = "identity") +
  coord_polar("y", start = 0) + # Transforma el gráfico de barras en un pastel
  labs(title = "Distribución General de Sentimientos en Reseñas",
       fill = "Sentimiento",
       caption = "Nota: El análisis se basa en un léxico con ~22% de cobertura de palabras únicas.") +
  theme_void() + # Un tema limpio para gráficos de pastel
  geom_text(aes(label = paste0(round(porcentaje, 1), "%")),
            position = position_stack(vjust = 0.5), size = 4) + # Añadir etiquetas de porcentaje
  scale_fill_manual(values = c("Negativo" = "#F8766D", "Neutro" = "#619CFF", "Positivo" = "#00BA38")) + # Colores personalizados
  theme(plot.title = element_text(hjust = 0.5)) # Centrar el título

#### 3.9. Clasificación Promedio  ####
promedio <- df_con_sentimientos$calificación %>%
  mean()

print(promedio)

#### 3.10 Gráfico de Correlación entre Calificación y Puntaje de Sentimientos ####
ggplot(df_con_sentimientos, aes(x = calificación, y = puntuacion)) +
  geom_point(col = "red") +
  geom_smooth(method = "lm", col = "red4") +
  labs(title = "Correlación entre Calificación y Puntaje de Sentimientos",
       x = "Calificación", y = "Puntaje",
       caption = "Nota: El análisis de sentimiento se basa en un léxico con ~22% de cobertura de palabras únicas.") +
  theme_minimal()

#### 3.11 Calcular Coeficiente de Relación de Pearson ####
corr_pearson <- cor(df_con_sentimientos$calificación, 
                    df_con_sentimientos$puntuacion, 
                    use = "pairwise.complete.obs") # Ignora NAs

print(paste("Coeficiente de Correlación (Pearson) entre Estrellas y Score de Sentimiento:",
            round(corr_pearson, 2)))

#El análisis visual y numérico (Coeficiente de Correlación de Pearson = 0.04) revela una correlación lineal insignificante 
#entre las puntuaciones de estrellas asignadas por los usuarios y el `score_sentimiento_total` inferido del texto. 
#Esta desconexión es atribuible principalmente a la limitada cobertura del léxico de sentimiento empleado 
#(aproximadamente 22% de las palabras únicas de las reseñas). 
#Al no poder evaluar una proporción significativa del vocabulario, el análisis léxico-basado pierde matices cruciales, 
#impidiendo que el sentimiento textual refleje consistentemente la valoración explícita del usuario. 
#Este hallazgo subraya la importancia de la calidad y exhaustividad del léxico en este tipo de análisis.

#### 3.12 Palabras Clave Dominantes en Reseñas Positivas y Negativas  ####
analisis_completo <- df_limpio %>%
  inner_join(reseña_clasificada, by = "id")

View(analisis_completo)

palabras_positivas <- analisis_completo %>%
  filter(sentimiento_final == "Positivo") %>%
  unnest_tokens(palabra, comentarios) %>%
  anti_join(stop_words_es, by = "palabra") %>%
  inner_join(lexico_sentimiento, by = "palabra") %>%
  count(palabra, sort = TRUE) %>%
  head(15)

View(palabras_positivas)

palabras_negativas <- analisis_completo %>%
  filter(sentimiento_final == "Negativo") %>%
  unnest_tokens(palabra, comentarios) %>%
  anti_join(stop_words_es, by = "palabra") %>%
  inner_join(lexico_sentimiento, by = "palabra") %>%
  count(palabra, sort = TRUE) %>%
  head(15)

View(palabras_negativas)

#### 3.13. Gráfico de las Palabras Clave  ####
ggplot(palabras_positivas, aes(x = reorder(palabra, n), y = n)) +
  geom_col(col = "green4") +
  coord_flip() +
  labs(title = "Top Palabras Clave en Reseñas Positivas",
       x = "Palabras Clave",
       y = "Frecuencia",
       caption = "Nota: Basado en las palabras encontradas en el léxico de sentimiento") +
  theme_minimal()

#Se ha identificado que la palabra "pésima" aparece en el top de términos asociados a reseñas clasificadas como 'Positivas'.
#Esta aparente inconsistencia es un claro ejemplo de las limitaciones del análisis de sentimientos puramente léxico-basado,
#especialmente con un léxico de cobertura limitada (~22%)
#y sin mecanismos avanzados para interpretar la negación, la ironía o el contexto global de la oración.
#Una reseña con un sentimiento general positivo (debido a la predominancia de otras palabras positivas en el léxico) 
#aún podría contener términos negativos aislados. Este hallazgo subraya la necesidad de herramientas más sofisticadas
#o léxicos de dominio específico para una interpretación más precisa del lenguaje natural.

ggplot(palabras_negativas, aes(x = reorder(palabra, n), y = n)) +
  geom_col(col = "red4") +
  coord_flip() +
  labs(title = "Top Palabras Clave en Reseñas Negativas",
       x = "Palabras Clave",
       y = "Frecuencia",
       caption = "Nota: Basado en las palabras encontradas en el léxico de sentimiento") +
  theme_minimal()
