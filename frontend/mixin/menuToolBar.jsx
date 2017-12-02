'use strict';
/**
 * Вернет компонет для toolbarMenu
 * @btnParams Параметры кнопок
 * @userData Данные пользователя
 * @returns {XML}
 */
const React = require('react');
const MenuToolBar = require('./../components/menu-toolbar/menu-toolbar.jsx');
const rendermenuToolBar = (btnParams, userData) => {
    return (
        <div>
            <MenuToolBar edited={false} params={btnParams} userData={userData} btnStartClick={this.btnStartClickHanler}/>
        </div>
    );
};

module.exports = rendermenuToolBar;

