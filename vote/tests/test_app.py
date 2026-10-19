import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_page_renders(client):
    """Verify that the voting homepage returns HTTP 200 and contains the voting options."""
    response = client.get('/')
    assert response.status_code == 200
    assert b'Cats' in response.data or b'Dogs' in response.data

def test_voter_cookie_assigned(client):
    """Verify that a voter ID cookie is generated if one does not exist."""
    response = client.get('/')
    assert response.status_code == 200
    cookies = response.headers.getlist('Set-Cookie')
    assert any('voter_id=' in cookie for cookie in cookies)
