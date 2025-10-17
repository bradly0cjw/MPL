/********************************************************************************
** Form generated from reading UI file 'mainwindow.ui'
**
** Created by: Qt User Interface Compiler version 5.15.13
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_MAINWINDOW_H
#define UI_MAINWINDOW_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QCheckBox>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QMainWindow>
#include <QtWidgets/QMenuBar>
#include <QtWidgets/QProgressBar>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSlider>
#include <QtWidgets/QSpinBox>
#include <QtWidgets/QStatusBar>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_MainWindow
{
public:
    QWidget *centralwidget;
    QPushButton *shine_Button;
    QPushButton *blink_Button;
    QCheckBox *led1_checkBox;
    QCheckBox *led2_checkBox;
    QCheckBox *led3_checkBox;
    QCheckBox *led4_checkBox;
    QLabel *led1_pics;
    QLineEdit *times_textedit;
    QLabel *led2_pics;
    QLabel *led3_pics;
    QLabel *led4_pics;
    QSlider *horizontalSlider;
    QProgressBar *progressBar;
    QSpinBox *spinBox;
    QMenuBar *menubar;
    QStatusBar *statusbar;

    void setupUi(QMainWindow *MainWindow)
    {
        if (MainWindow->objectName().isEmpty())
            MainWindow->setObjectName(QString::fromUtf8("MainWindow"));
        MainWindow->resize(800, 600);
        centralwidget = new QWidget(MainWindow);
        centralwidget->setObjectName(QString::fromUtf8("centralwidget"));
        shine_Button = new QPushButton(centralwidget);
        shine_Button->setObjectName(QString::fromUtf8("shine_Button"));
        shine_Button->setGeometry(QRect(510, 220, 91, 22));
        blink_Button = new QPushButton(centralwidget);
        blink_Button->setObjectName(QString::fromUtf8("blink_Button"));
        blink_Button->setGeometry(QRect(410, 220, 91, 22));
        led1_checkBox = new QCheckBox(centralwidget);
        led1_checkBox->setObjectName(QString::fromUtf8("led1_checkBox"));
        led1_checkBox->setGeometry(QRect(260, 120, 85, 20));
        led2_checkBox = new QCheckBox(centralwidget);
        led2_checkBox->setObjectName(QString::fromUtf8("led2_checkBox"));
        led2_checkBox->setGeometry(QRect(260, 150, 85, 20));
        led3_checkBox = new QCheckBox(centralwidget);
        led3_checkBox->setObjectName(QString::fromUtf8("led3_checkBox"));
        led3_checkBox->setGeometry(QRect(260, 180, 85, 20));
        led4_checkBox = new QCheckBox(centralwidget);
        led4_checkBox->setObjectName(QString::fromUtf8("led4_checkBox"));
        led4_checkBox->setGeometry(QRect(260, 210, 85, 20));
        led1_pics = new QLabel(centralwidget);
        led1_pics->setObjectName(QString::fromUtf8("led1_pics"));
        led1_pics->setGeometry(QRect(230, 120, 21, 21));
        led1_pics->setPixmap(QPixmap(QString::fromUtf8("off.png")));
        times_textedit = new QLineEdit(centralwidget);
        times_textedit->setObjectName(QString::fromUtf8("times_textedit"));
        times_textedit->setGeometry(QRect(410, 180, 113, 22));
        led2_pics = new QLabel(centralwidget);
        led2_pics->setObjectName(QString::fromUtf8("led2_pics"));
        led2_pics->setGeometry(QRect(230, 150, 21, 21));
        led2_pics->setPixmap(QPixmap(QString::fromUtf8("off.png")));
        led3_pics = new QLabel(centralwidget);
        led3_pics->setObjectName(QString::fromUtf8("led3_pics"));
        led3_pics->setGeometry(QRect(230, 180, 21, 21));
        led3_pics->setPixmap(QPixmap(QString::fromUtf8("off.png")));
        led4_pics = new QLabel(centralwidget);
        led4_pics->setObjectName(QString::fromUtf8("led4_pics"));
        led4_pics->setGeometry(QRect(230, 210, 21, 21));
        led4_pics->setPixmap(QPixmap(QString::fromUtf8("off.png")));
        horizontalSlider = new QSlider(centralwidget);
        horizontalSlider->setObjectName(QString::fromUtf8("horizontalSlider"));
        horizontalSlider->setGeometry(QRect(410, 110, 160, 16));
        horizontalSlider->setOrientation(Qt::Horizontal);
        progressBar = new QProgressBar(centralwidget);
        progressBar->setObjectName(QString::fromUtf8("progressBar"));
        progressBar->setGeometry(QRect(410, 140, 118, 23));
        progressBar->setValue(24);
        spinBox = new QSpinBox(centralwidget);
        spinBox->setObjectName(QString::fromUtf8("spinBox"));
        spinBox->setGeometry(QRect(530, 140, 43, 23));
        MainWindow->setCentralWidget(centralwidget);
        menubar = new QMenuBar(MainWindow);
        menubar->setObjectName(QString::fromUtf8("menubar"));
        menubar->setGeometry(QRect(0, 0, 800, 19));
        MainWindow->setMenuBar(menubar);
        statusbar = new QStatusBar(MainWindow);
        statusbar->setObjectName(QString::fromUtf8("statusbar"));
        MainWindow->setStatusBar(statusbar);

        retranslateUi(MainWindow);
        QObject::connect(horizontalSlider, SIGNAL(valueChanged(int)), progressBar, SLOT(setValue(int)));
        QObject::connect(spinBox, SIGNAL(valueChanged(int)), horizontalSlider, SLOT(setValue(int)));
        QObject::connect(horizontalSlider, SIGNAL(valueChanged(int)), spinBox, SLOT(setValue(int)));

        QMetaObject::connectSlotsByName(MainWindow);
    } // setupUi

    void retranslateUi(QMainWindow *MainWindow)
    {
        MainWindow->setWindowTitle(QCoreApplication::translate("MainWindow", "MainWindow", nullptr));
        shine_Button->setText(QCoreApplication::translate("MainWindow", "LED Shining", nullptr));
        blink_Button->setText(QCoreApplication::translate("MainWindow", "LED Switching", nullptr));
        led1_checkBox->setText(QCoreApplication::translate("MainWindow", "LED1", nullptr));
        led2_checkBox->setText(QCoreApplication::translate("MainWindow", "LED2", nullptr));
        led3_checkBox->setText(QCoreApplication::translate("MainWindow", "LED3", nullptr));
        led4_checkBox->setText(QCoreApplication::translate("MainWindow", "LED4", nullptr));
        led1_pics->setText(QString());
        led2_pics->setText(QString());
        led3_pics->setText(QString());
        led4_pics->setText(QString());
    } // retranslateUi

};

namespace Ui {
    class MainWindow: public Ui_MainWindow {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_MAINWINDOW_H
