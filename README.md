# **Customer Review Sentiment Analysis with R**

## **Project Overview**
This project focuses on performing a sentiment analysis on a dataset of synthetic customer reviews. The primary goal is to extract actionable insights regarding customer perceptions, identify key drivers of satisfaction and dissatisfaction, and understand the relationship between explicit star ratings and the underlying textual sentiment. This analysis leverages Natural Language Processing (NLP) techniques in R, specifically a lexicon-based approach.

## **Business Questions Addressed**
This analysis aims to answer the following key questions from a stakeholder's perspective:

* What is the overall sentiment of our customers towards the product?
* What are the specific aspects of the product that our customers appreciate most or find most dissatisfying?
* Is there a discrepancy between customer-assigned star ratings and the sentiment expressed in the review text?

## **Data Source**
The project utilizes a synthetic dataset of customer reviews, accompanied by a custom sentiment lexicon for Spanish.

* reseñas_audifonos_sinteticas.csv - Contains **100** customer reviews, each with a comments column and a rating column.

* lexico_afinn.csv - A custom sentiment lexicon with **3461** words and their associated sentiment scores.

## **Methodology**
The analysis follows a standard NLP pipeline:

* Data Loading & Preprocessing: Reviews are loaded, cleaned (lowercase conversion, punctuation/number removal), and tokenized into individual words. Spanish stop words are removed to focus on meaningful terms.

* Lexicon-Based Sentiment Scoring: A custom sentiment lexicon is applied to score each word. Review sentiment is then aggregated by summing individual word scores.

* Sentiment Classification: Each review is classified as "Positive," "Negative," or "Neutral" based on its aggregate sentiment score.

* Insight Generation: Visualizations (pie charts, scatter plots, bar charts of keywords) and statistical measures (Pearson correlation) are used to answer the business questions.

## **Key Findings & Insights**
* Overall Sentiment Distribution: The analysis revealed a notable polarization of sentiments, with approximately 51% of reviews classified as positive and 41% as negative.

* Star Rating vs. Textual Sentiment: A negligible linear correlation (Pearson R = 0.04) was observed between star ratings and the derived textual sentiment score. This highlights that explicit star ratings may not always capture the nuances of customer feedback present in the text.

* Dominant Keywords:
  * Positive Reviews frequently mention terms such as "increíble," "buenos," and "satisfecho".
  * Negative Reviews commonly feature words like "problemas," "horrible," and "espera".

## **Limitations**
Lexicon Coverage: The primary limitation is the limited coverage of the sentiment lexicon (~22% of unique words). A significant portion of review vocabulary was not evaluated, potentially affecting the granularity and accuracy of sentiment scores.

Lexicon-Based Approach: This method does not account for complex linguistic phenomena like negation, sarcasm, or contextual meaning, which can lead to misinterpretations (e.g., a word like "pésima" appearing in a predominantly "Positive" review).

Synthetic Data: The use of synthetic data may not fully reflect the complexities and irregularities of real-world customer language.

## **Technologies Used**
* R
* dplyr for data manipulation
* tidytext for text mining operations
* ggplot2 for data visualization
* readr for data import
* stringr for string operations
* stopwords for stop word management

## **Contact**
Feel free to connect or reach out with any questions:

Samuel Vázquez Aguirre

LinkedIn: https://www.linkedin.com/in/samuel-vazquez7295/
