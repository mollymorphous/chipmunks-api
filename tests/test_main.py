async def test_hello(client):
    assert (await client.get("/")).json() == {"message": "Hello, Chipmunks!"}
