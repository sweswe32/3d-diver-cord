package main

import (
	"fmt"
	"math/rand"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"
)

type Agent struct {
	x, y, z   float64
	xVelocity float64
	yVelocity float64
	zVelocity float64
	dt        float64
}

func (a *Agent) update() {
	// Чтение данных (имитация)
	xAcc := rand.Float64()*2 - 1 // Ускорение в диапазоне от -1 до 1 м/с²
	yAcc := rand.Float64()*2 - 1
	zAcc := rand.Float64()*2 - 1

	// Обновление скорости
	a.xVelocity += xAcc * a.dt
	a.yVelocity += yAcc * a.dt
	a.zVelocity += zAcc * a.dt

	// Обновление координат
	a.x += a.xVelocity * a.dt
	a.y += a.yVelocity * a.dt
	a.z += a.zVelocity * a.dt

	// Вывод данных
	fmt.Printf("Ускорение: x=%.2f м/с², y=%.2f м/с², z=%.2f м/с²\n", xAcc, yAcc, zAcc)

	// Генерация случайных значений для магнитного поля
	mx := rand.Float64()*200 - 100 // Магнитное поле в диапазоне от -100 до 100 µT
	my := rand.Float64()*200 - 100
	mz := rand.Float64()*200 - 100
	fmt.Printf("Магнитное поле: mx=%.2f µT, my=%.2f µT, mz=%.2f µT\n", mx, my, mz)

	// Генерация случайного расстояния
	distance := rand.Float64() * 400 // Расстояние в диапазоне от 0 до 400 см
	fmt.Printf("Расстояние: %.2f см\n", distance)

	// Вывод текущих координат
	fmt.Printf("Координаты: x=%.2f, y=%.2f, z=%.2f\n", a.x, a.y, a.z)
	fmt.Println(strings.Repeat("-", 40)) // Разделитель
}

func main() {
	rand.Seed(time.Now().UnixNano())
	agent := Agent{dt: 1.0}

	// Обработка сигналов для корректного завершения программы
	sigs := make(chan os.Signal, 1)
	signal.Notify(sigs, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		<-sigs
		fmt.Println("\nСимуляция остановлена пользователем.")
		os.Exit(0)
	}()

	for { // Бесконечный цикл
		agent.update()
		time.Sleep(1 * time.Second) // Пауза между итерациями
	}
}
