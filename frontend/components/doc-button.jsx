'use strict';

const React = require('react');

const DocButton = (props)=> {
    let btnEnabled = props.enabled ? true: false, // установим значение по умолчанию
        className = props.className || null,
        style = {margin: 5},
        refId = props.refId || 'docButton';
//                   className = {className}

    return <input type="button"
                  value={props.value}
                  disabled = {btnEnabled}
                  onClick={props.onClick}
                  className={className}
                  style = {{style}}
    />
};

DocButton.propTypes = {
    onClick: React.PropTypes.func.isRequired,
    value: React.PropTypes.string.isRequired
}
//     className: React.PropTypes.string

module.exports = DocButton
