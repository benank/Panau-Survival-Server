function Distance2D(a, b)
    return Vector2(a.x, a.z):Distance(Vector2(b.x, b.z))
end