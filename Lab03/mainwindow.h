#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <string>

// Required for GPIO control
#include <unistd.h>
#include <fcntl.h>

// Add QPixmap for images
#include <QPixmap>

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void on_led1_checkBox_toggled(bool checked);
    void on_led2_checkBox_toggled(bool checked);
    void on_led3_checkBox_toggled(bool checked);
    void on_led4_checkBox_toggled(bool checked);
    void on_shine_Button_clicked();
    void on_blink_Button_clicked();
    void onTaskFinished();

private:
    Ui::MainWindow *ui;

    // GPIO pin numbers
    const int LED1_GPIO = 396;
    const int LED2_GPIO = 397;
    const int LED3_GPIO = 254;
    const int LED4_GPIO = 389;

    // Member variables to hold the loaded images
    QPixmap m_ledOnPixmap;
    QPixmap m_ledOffPixmap;

    // GPIO control functions
    int gpio_export(unsigned int gpio);
    int gpio_unexport(unsigned int gpio);
    int gpio_set_dir(unsigned int gpio, const std::string &dirStatus);
    int gpio_set_value(unsigned int gpio, int value);

    void handle_led(int gpio, bool on);
    // Main function for controlling LED state and UI
    void set_led_state(int gpio, bool on);

    // UI management
    void setUiEnabled(bool enabled);
    void update_led_indicator(int gpio, bool on);

    // Functions to be run in a separate thread
    void perform_shine(int count);
    void perform_blink(QList<int> gpios, int count);
};
#endif // MAINWINDOW_H
