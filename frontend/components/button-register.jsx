'use strict';

const React = require('react');

const ButtonRegister = (props) => {
// кнопка создания документа в регистрах
        return <input type="button"
                      className="gridToolbar"
                      value={props.value}
                      onClick={props.onClick}/>
};

ButtonRegister.propTypes = {
    onClick: React.PropTypes.func.isRequired,
    value: React.PropTypes.string.isRequired
}

module.exports = ButtonRegister;