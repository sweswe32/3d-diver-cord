import random

class LSM9DS1:
    def __init__(self):
        self.last_x = 0.0
        self.last_y = 0.0
        self.last_z = 0.0

    def read_acceleration(self):
        max_change = 2.0  # Максимальное изменение ускорения за итерацию
        x_change = random.uniform(-max_change, max_change)
        y_change = random.uniform(-max_change, max_change)
        z_change = random.uniform(-max_change, max_change)

        self.last_x += x_change
        self.last_y += y_change
        self.last_z += z_change

        self.last_x = max(-10.0, min(self.last_x, 10.0))
        self.last_y = max(-10.0, min(self.last_y, 10.0))
        self.last_z = max(-10.0, min(self.last_z, 10.0))

        return self.last_x, self.last_y, self.last_z

    def read_magnetometer(self):
        mx = random.uniform(-100.0, 100.0)  # Магнитное поле по оси X
        my = random.uniform(-100.0, 100.0)  # Магнитное поле по оси Y
        mz = random.uniform(-100.0, 100.0)  # Магнитное поле по оси Z
        return mx, my, mz