print(" THIS IS THE NEW FILE RUNNING")

import pandas as pd
import pickle
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.linear_model import LogisticRegression

df = pd.read_csv("data/intents.csv")

print("Columns:", df.columns)

X = df["text"]
y = df["intent"]

vectorizer = TfidfVectorizer()
X_vec = vectorizer.fit_transform(X)

model = LogisticRegression(max_iter=1000)
model.fit(X_vec, y)

pickle.dump(model, open("models/lr_model.pkl", "wb"))
pickle.dump(vectorizer, open("models/vectorizer.pkl", "wb"))

print(" Model trained successfully!")
