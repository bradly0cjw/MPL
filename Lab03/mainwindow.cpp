#include "mainwindow.h"
#include "ui_mainwindow.h"

#include <QDebug>
#include <QtConcurrent/QtConcurrent>
#include <QFuture>
#include <QFutureWatcher>
#include <QIntValidator>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);
    // Optional: Add a validator to ensure only integers can be entered
    ui->times_textedit->setValidator(new QIntValidator(1, 1000, this));
    ui->times_textedit->setText("5"); // Set an initial value

    m_ledOnPixmap.load("/home/nvidia/Group10/Lab03/Image/on.png");
    m_ledOffPixmap.load("/home/nvidia/Group10/Lab03/Image/off.png");

    update_led_indicator(LED1_GPIO, false);
    update_led_indicator(LED2_GPIO, false);
    update_led_indicator(LED3_GPIO, false);
    update_led_indicator(LED4_GPIO, false);
}

MainWindow::~MainWindow()
{
    // Ensure all LEDs are off and unexported on exit
    gpio_set_value(LED1_GPIO, 0);
    gpio_unexport(LED1_GPIO);
    gpio_set_value(LED2_GPIO, 0);
    gpio_unexport(LED2_GPIO);
    gpio_set_value(LED3_GPIO, 0);
    gpio_unexport(LED3_GPIO);
    gpio_set_value(LED4_GPIO, 0);
    gpio_unexport(LED4_GPIO);
    delete ui;
}

// --- GPIO Control Functions ---

int MainWindow::gpio_export(unsigned int gpio)
{
    int fd = open("/sys/class/gpio/export", O_WRONLY);
    if (fd < 0) {
        perror("gpio/export");
        return fd;
    }
    char buf[64];
    int len = snprintf(buf, sizeof(buf), "%d", gpio);
    write(fd, buf, len);
    ::close(fd); // FIX: Use global namespace for close()
    return 0;
}

int MainWindow::gpio_unexport(unsigned int gpio)
{
    int fd = open("/sys/class/gpio/unexport", O_WRONLY);
    if (fd < 0) {
        perror("gpio/unexport");
        return fd;
    }
    char buf[64];
    int len = snprintf(buf, sizeof(buf), "%d", gpio);
    write(fd, buf, len);
    ::close(fd); // FIX: Use global namespace for close()
    return 0;
}

int MainWindow::gpio_set_dir(unsigned int gpio, const std::string &dirStatus)
{
    char buf[64];
    snprintf(buf, sizeof(buf), "/sys/class/gpio/gpio%d/direction", gpio);
    int fd = open(buf, O_WRONLY);
    if (fd < 0) {
        perror("gpio/direction");
        return fd;
    }
    if (dirStatus == "out") {
        write(fd, "out", 3);
    } else {
        write(fd, "in", 2);
    }
    ::close(fd); // FIX: Use global namespace for close()
    return 0;
}

int MainWindow::gpio_set_value(unsigned int gpio, int value)
{
    char buf[64];
    snprintf(buf, sizeof(buf), "/sys/class/gpio/gpio%d/value", gpio);
    int fd = open(buf, O_WRONLY);
    if (fd < 0) {
        perror("gpio/set-value");
        return fd;
    }
    if (value == 0) {
        write(fd, "0", 1);
    } else {
        write(fd, "1", 1);
    }
    ::close(fd); // FIX: Use global namespace for close()
    return 0;
}

// --- UI Slots and Helpers ---

void MainWindow::handle_led(int gpio, bool on)
{
    if (on) {
        gpio_export(gpio);
        gpio_set_dir(gpio, "out");
        gpio_set_value(gpio, 1);
    } else {
        gpio_set_value(gpio, 0);
        gpio_unexport(gpio);
    }
}

void MainWindow::setUiEnabled(bool enabled)
{
    ui->led1_checkBox->setEnabled(enabled);
    ui->led2_checkBox->setEnabled(enabled);
    ui->led3_checkBox->setEnabled(enabled);
    ui->led4_checkBox->setEnabled(enabled);
    ui->shine_Button->setEnabled(enabled);
    ui->blink_Button->setEnabled(enabled);
    ui->times_textedit->setEnabled(enabled);
}

void MainWindow::onTaskFinished()
{
    setUiEnabled(true);
}

// NOTE: Renamed slots to match UI object names
void MainWindow::on_led1_checkBox_toggled(bool checked)
{
    // handle_led(LED1_GPIO, checked);
}

void MainWindow::on_led2_checkBox_toggled(bool checked)
{
    // handle_led(LED2_GPIO, checked);
}

void MainWindow::on_led3_checkBox_toggled(bool checked)
{
    // handle_led(LED3_GPIO, checked);
}

void MainWindow::on_led4_checkBox_toggled(bool checked)
{
    // handle_led(LED4_GPIO, checked);
}

void MainWindow::on_shine_Button_clicked()
{
    setUiEnabled(false);
    // FIX: Convert QString to int
    int count = ui->times_textedit->text().toInt();

    QFutureWatcher<void> *watcher = new QFutureWatcher<void>(this);
    connect(watcher, &QFutureWatcher<void>::finished, this, &MainWindow::onTaskFinished);

    QFuture<void> future = QtConcurrent::run(this, &MainWindow::perform_shine, count);
    watcher->setFuture(future);
}


void MainWindow::update_led_indicator(int gpio, bool on)
{
    QLabel *indicator_label = nullptr;
    if (gpio == LED1_GPIO) indicator_label = ui->led1_pics;
    else if (gpio == LED2_GPIO) indicator_label = ui->led2_pics;
    else if (gpio == LED3_GPIO) indicator_label = ui->led3_pics;
    else if (gpio == LED4_GPIO) indicator_label = ui->led4_pics;

    if (indicator_label) {
        indicator_label->setPixmap(on ? m_ledOnPixmap : m_ledOffPixmap);
    }
}

void MainWindow::on_blink_Button_clicked()
{
    QList<int> gpio_status;
    gpio_status << (ui->led1_checkBox->isChecked() ? 1 : 0);
    gpio_status << (ui->led2_checkBox->isChecked() ? 1 : 0);
    gpio_status << (ui->led3_checkBox->isChecked() ? 1 : 0);
    gpio_status << (ui->led4_checkBox->isChecked() ? 1 : 0);

    handle_led(LED1_GPIO, gpio_status[0]);
    handle_led(LED2_GPIO, gpio_status[1]);
    handle_led(LED3_GPIO, gpio_status[2]);
    handle_led(LED4_GPIO, gpio_status[3]);
    update_led_indicator(LED1_GPIO, gpio_status[0]);
    update_led_indicator(LED2_GPIO, gpio_status[1]);
    update_led_indicator(LED3_GPIO, gpio_status[2]);
    update_led_indicator(LED4_GPIO, gpio_status[3]);


}


// --- Background Tasks ---

void MainWindow::perform_shine(int count)
{
    for (int i = 0; i < count * 2; i++) {
        if (i % 2 == 0) {
            handle_led(LED1_GPIO, true);
            handle_led(LED2_GPIO, true);
            update_led_indicator(LED1_GPIO, true);
            update_led_indicator(LED2_GPIO, true);
            usleep(300000); // 300ms
            handle_led(LED1_GPIO, false);
            handle_led(LED2_GPIO, false);
            update_led_indicator(LED1_GPIO, false);
            update_led_indicator(LED2_GPIO, false);
        } else {
            handle_led(LED4_GPIO, true);
            handle_led(LED3_GPIO, true);
            update_led_indicator(LED4_GPIO, true);
            update_led_indicator(LED3_GPIO, true);
            usleep(300000); // 300ms
            handle_led(LED4_GPIO, false);
            handle_led(LED3_GPIO, false);
            update_led_indicator(LED3_GPIO, false);
            update_led_indicator(LED4_GPIO, false);
        }
        usleep(300000); // 300ms delay between cycles
    }
}

void MainWindow::perform_blink(QList<int> gpios, int count)
{
    // Export all selected GPIOs first
    for(int gpio : gpios) {
        gpio_export(gpio);
        gpio_set_dir(gpio, "out");
    }

    for (int i = 0; i < count; ++i) {
        // Turn all on
        for(int gpio : gpios) {
            gpio_set_value(gpio, 1);
        }
        usleep(500000); // 500ms on

        // Turn all off
        for(int gpio : gpios) {
            gpio_set_value(gpio, 0);
        }
        usleep(500000); // 500ms off
    }

    // Unexport all when done
    for(int gpio : gpios) {
        gpio_unexport(gpio);
    }
}
