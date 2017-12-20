// виджет, объединяющий селект и текст. в тексте отражаютмя данные, связанные с селектом
'use strict';

const PropTypes = require('prop-types');
const Select = require('../select/select.jsx');
const Text = require ('../text-area/text-area.jsx');

const React = require('react');

    class SelectTextWidget extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            value: props.value,
            description: '', // пойдет в текстовую область
            libData: []
        };
        this.handleSelectOnChange = this.handleSelectOnChange.bind(this);
    }


    handleSelectOnChange(e, name, value) {
        // отработаем событие и поменяем состояние
        if (this.state.libData) {
            let selg = this.getDescriptionBySelectValue(this.state.libData) || null;
            this.setState({value: value, description: selg});
        }
    }

    getDescriptionBySelectValue(libData) {
        // найдем в справочнике описание и установим его состояние
        let libRow = libData.filter((lib) => {

                if (lib.id == this.props.value) {
                    return lib;
                }
            }),
            selg = '',
            selgObject = libRow.length ? libRow[0].details : '';

        for (let property in selgObject) {
            if (selgObject.hasOwnProperty(property)) {
                // интересуют только "собственные" свойства объекта
                selg = selg + property + ':' + selgObject[property];
            }
        }
        return selg;
    }

    render() {
        return (
            <div>
                <Select className={this.props.className}
                        ref = "select"
                        title={this.props.title}
                        name={this.props.name}
                        libs={this.props.libs}
                        value={this.props.value || ''}
                        defaultValue={this.props.defaultValue || ''}
                        placeholder={this.props.placeholder || this.props.title}
                        readOnly={this.props.readOnly}
                        onChange={this.handleSelectOnChange}
                />
                <Text ref = "text"
                      name='muud'
                      placeholder='DokProp'
                      value={this.state.description || ''}
                      readOnly={true}
                      disabled={true}
                />

            </div>
        );
    }
}

SelectTextWidget.propTypes = {
    value: PropTypes.number,
    name: PropTypes.string.isRequired,
    title: PropTypes.string,
    libs: PropTypes.string,
    defaultValue: PropTypes.string,
    readOnly: PropTypes.bool,
    placeholder: PropTypes.string
};


SelectTextWidget.defaultProps = {
    readOnly: false,
    title: ''
};

module.exports = SelectTextWidget;

