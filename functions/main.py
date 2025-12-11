import firebase_admin
from firebase_admin import initialize_app # Hanya ambil yang dibutuhkan dari Admin SDK
import requests
import os

# Import yang sangat spesifik dari Functions SDK
# Kami akan mengimpor dekorator CALLABLE dengan nama yang jelas.
from firebase_functions import https_fn # <-- GUNAKAN NAMA INI UNTUK DEKORATOR


# --- INISIALISASI ADMIN SDK (Global/Lazy Loading) ---
app_initialized = False

def initialize_firebase_app():
    global app_initialized
    if not app_initialized:
        try:
            firebase_admin.initialize_app()
            app_initialized = True
            print("Firebase Admin App Initialized.")
        except ValueError:
            app_initialized = True
            pass

initialize_firebase_app()

# --- KONFIGURASI LAINNYA ---
GOOGLE_API_KEY = os.environ.get('GOOGLE_KEY') 
BASE_URL = 'https://maps.googleapis.com/maps/api/place/'

# ===========================================
# FUNGSI 1: searchPlaces 
# ===========================================
# ✅ Gunakan nama 'https_fn' yang sudah diimpor:
@https_fn.on_call()
def searchPlaces(data, context):
    print(f"DEBUG_KEY: {bool(os.environ.get('GOOGLE_KEY'))}")
    print(f"DEBUG_KEY_START: {os.environ.get('GOOGLE_KEY')[:5]}")   
    input_text = data.get('input')
    session_token = data.get('sessionToken')
    
    if not input_text or len(input_text) < 3:
        return {'status': 'INVALID_ARGUMENT', 'predictions': []}

    endpoint = 'autocomplete/json'
    params = {
        'input': input_text,
        'key': GOOGLE_API_KEY,
        'sessiontoken': session_token,
        'components': 'country:id'
    }

    try:
        response = requests.get(f'{BASE_URL}{endpoint}', params=params)
        response.raise_for_status() 
        return response.json()
        
    except requests.exceptions.RequestException as e:
        print(f"Google Maps Autocomplete Error: {e}")
        return {'status': 'SERVER_ERROR', 'error_message': 'Failed to communicate with Google Maps API'}
    except Exception as e:
        print(f"General Error in searchPlaces: {e}")
        return {'status': 'SERVER_ERROR', 'error_message': str(e)}


# ===========================================
# FUNGSI 2: getPlaceDetails
# ===========================================
# ✅ Gunakan nama 'https_fn' yang sudah diimpor:
@https_fn.on_call()
def getPlaceDetails(data, context):
    place_id = data.get('placeId')
    session_token = data.get('sessionToken')
    
    if not place_id:
        return {'status': 'INVALID_ARGUMENT', 'error_message': 'Place ID is missing'}

    endpoint = 'details/json'
    fields = 'geometry,name,formatted_address'
    params = {
        'place_id': place_id,
        'key': GOOGLE_API_KEY,
        'session_token': session_token, 
        'fields': fields
    }

    try:
        response = requests.get(f'{BASE_URL}{endpoint}', params=params)
        response.raise_for_status() 

        return response.json()
        
    except requests.exceptions.RequestException as e:
        print(f"Google Maps Details Error: {e}")
        return {'status': 'SERVER_ERROR', 'error_message': 'Failed to communicate with Google Maps API'}
    except Exception as e:
        print(f"General Error in getPlaceDetails: {e}")
        return {'status': 'SERVER_ERROR', 'error_message': str(e)}