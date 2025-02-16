
import time
from RPi_GPIO import LSM9DS1, HCSR04

def main():
    lsm9ds1 = LSM9DS1()
    hcsr04 = HCSR04()

    try:
        while True:
            # Получаем данные с датчиков
            x, y, z = lsm9ds1.read_acceleration()
            distance = hcsr04.measure_distance()

            # Выводим данные
            print(f"Координаты: x={x:.2f}, y={y:.2f}, z={z:.2f} | Расстояние: {distance:.2f} см")
            time.sleep(1)  # Пауза между измерениями

    except KeyboardInterrupt:
        print("Симуляция остановлена пользователем.")

if __name__ == "__main__":
    main()