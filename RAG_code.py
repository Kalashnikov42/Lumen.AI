import pandas as pd
import requests
from bs4 import BeautifulSoup
from sentence_transformers import SentenceTransformer
import faiss
import numpy as np
import botpress_sdk
import json
import time
import logging

# Setting up logging for debugging and tracking purposes
logging.basicConfig(level=logging.INFO)

# Load a list of URLs from a CSV file
def load_urls(csv_file):
    try:
        df = pd.read_csv(csv_file)
        return df['URL'].tolist()
    except Exception as e:
        logging.error(f"Error loading URLs from {csv_file}: {e}")
        return []

# Function to scrape web pages and extract text content
def scrape_data(url):
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            soup = BeautifulSoup(response.text, 'html.parser')
            paragraphs = soup.find_all('p')
            text = ' '.join([p.get_text() for p in paragraphs])
            logging.info(f"Scraped data from {url}")
            return text
        else:
            logging.warning(f"Failed to retrieve data from {url}. Status code: {response.status_code}")
            return ''
    except requests.RequestException as e:
        logging.error(f"Error scraping {url}: {e}")
        return ''

# Clean up extracted text by removing unnecessary newlines and spaces
def preprocess_text(text):
    text = text.replace('\n', ' ').strip()
    text = ' '.join(text.split())  # Removing extra spaces
    return text

# Create and store embeddings for the scraped text using FAISS (a vector search library)
def create_faiss_index(texts, model):
    try:
        embeddings = np.array([model.encode(text) for text in texts], dtype='float32')
        index = faiss.IndexFlatL2(embeddings.shape[1])  # Creating an index for fast search
        index.add(embeddings)  # Adding embeddings to the index
        logging.info("FAISS index created and embeddings added successfully.")
        return index, embeddings
    except Exception as e:
        logging.error(f"Error creating FAISS index: {e}")
        return None, None

# Search for the most relevant documents given a query
def retrieve_documents(query, model, index, texts, k=3):
    try:
        query_embedding = np.array([model.encode(query)], dtype='float32')
        _, indices = index.search(query_embedding, k)  # Retrieve top-k similar texts
        relevant_documents = [texts[i] for i in indices[0] if i < len(texts)]
        logging.info(f"Retrieved {k} documents for query: {query}")
        return relevant_documents
    except Exception as e:
        logging.error(f"Error retrieving documents: {e}")
        return []

# Generate a response by picking relevant context from retrieved documents
def generate_response(query, context):
    response = f"Based on what I found, here's a response: {context[:500]}..."
    logging.info(f"Generated response for query: {query}")
    return response

# Save FAISS index to a file for later use
def save_faiss_index(index, file_path):
    try:
        faiss.write_index(index, file_path)
        logging.info(f"FAISS index saved to {file_path}")
    except Exception as e:
        logging.error(f"Error saving FAISS index: {e}")

# Load FAISS index from a file
def load_faiss_index(file_path, dimension):
    try:
        index = faiss.IndexFlatL2(dimension)
        index = faiss.read_index(file_path)
        logging.info(f"FAISS index loaded from {file_path}")
        return index
    except Exception as e:
        logging.error(f"Error loading FAISS index: {e}")
        return None

# Send chatbot responses to BotPress via API integration
def send_to_botpress(response, user_id):
    try:
        botpress_token = "bt-43455666543ae234"
        botpress_url = "https://your-botpress-instance.com/api/v1/chat/sendMessage"
        headers = {"Authorization": f"Bearer {botpress_token}", "Content-Type": "application/json"}
        payload = {"userId": user_id, "message": response}
        
        # Push the response in a compatible format that BotPress expects
        payload['type'] = 'text'  # Specify the message type
        payload['payload'] = {'text': response}  # Use 'payload' field as per BotPress API
        response = requests.post(botpress_url, headers=headers, json=payload)
        response.raise_for_status()
        logging.info(f"Response sent to BotPress for user {user_id}.")
    except requests.RequestException as e:
        logging.error(f"Error sending message to BotPress: {e}")

# Background process to refresh FAISS index periodically
def refresh_faiss(url_list, model):
    global faiss_index, scraped_texts
    while True:
        try:
            logging.info("Refreshing FAISS index with new scraped data...")
            scraped_texts = [scrape_data(url) for url in url_list]
            scraped_texts = [preprocess_text(text) for text in scraped_texts if text]
            faiss_index, _ = create_faiss_index(scraped_texts, model)
            save_faiss_index(faiss_index, 'faiss_index.bin')
            time.sleep(3600)  # Refresh every hour
        except Exception as e:
            logging.error(f"Error refreshing FAISS index: {e}")
            time.sleep(3600)

# Main function to load URLs and scrape their text content
def main():
    url_list = load_urls('urls.csv')
    scraped_texts = [scrape_data(url) for url in url_list]
    scraped_texts = [preprocess_text(text) for text in scraped_texts if text]

    # Initialize the model and create FAISS index
    model = SentenceTransformer('all-MiniLM-L6-v2')
    faiss_index, _ = create_faiss_index(scraped_texts, model)
    save_faiss_index(faiss_index, 'faiss_index.bin')

    # Optionally start the background process for refreshing the FAISS index
    # refresh_faiss(url_list, model)

    # Example query
    query = "What are the latest trends in AI?"
    relevant_documents = retrieve_documents(query, model, faiss_index, scraped_texts, k=3)
    context = ' '.join(relevant_documents)
    response = generate_response(query, context)
    send_to_botpress(response, user_id="awefrtwgvsrhyt2345$%^5646123")

if __name__ == "__main__":
    main()
