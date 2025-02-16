import random

class LSM9DS1:
    def __init__(self):
        pass

    def read_acceleration(self):
        # Возвращаем случайные значения для x, y, z
        x = random.uniform(-10.0, 10.0)  # Ускорение по оси X
        y = random.uniform(-10.0, 10.0)  # Ускорение по оси Y
        z = random.uniform(-10.0, 10.0)  # Ускорение по оси Z
        return x, y, z