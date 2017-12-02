'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('./grid-filter-styles');


class GridFilter extends React.PureComponent {
    constructor(props) {
        super(props);

        this.state = {
            gridConfig: this.props.gridConfig, // grid config
            data: this.props.data // filter data
        };

        this.data = this.props.data;
        this.handleChange = this.handleChange.bind(this)    }

    /**
     * Обработчик на изменения инпутов
     * @param e
     */
    handleChange(e) {
        let value = e.target.value,
            id = e.target.name,
            index;

        // надо найти элемент массива с данными для этого компонента
        for(let i = 0; i < this.data.length; i++ ) {
            if (this.data[i].name === id) {
                index = i;
                break;
            }
        }

        if (index) {
            this.data[index].value = value;
        }


        if (this.props.handler) {
            this.props.handler(this.data);
        }
    }

    componentWillReceiveProps(nextProps) {
        this.data = nextProps.data;
        this.setState({gridConfig: nextProps.gridConfig});
    }

    render() {
        let isInitData =  !this.data.length;

            // создаст из полей грида компоненты для формирования условий фильтрации
        return <div style={styles.fieldset}>
            {
                this.props.gridConfig.map((row) => {
                    let componentType = row.type? row.type: 'text';

                    if (isInitData) {
                        // props.data пустое, создаем
                        this.data.push({value:null, name: row.id, type: componentType});
                    }

                    return <div style={styles.formWidget} key={'fieldSet-' + row.id}>
                        <div style={styles.formWidgetLabel}>
                            <span>{row.name}</span>
                        </div>
                        <div style={styles.formWidgetInput}>
                            <input style={styles.input}
                                   type={componentType}
                                   title={row.name}
                                   name={row.id}
                                   placeholder={row.name}
                                   ref={row.id}
                                   value = {this.props.data[row.id]}
                                   onChange={this.handleChange}
                                   defaultValue={this.props.data[row.id]}
                            />
                        </div>
                    </div>
                })
            }
        </div>
    }
}

GridFilter.propTypes = {
    gridConfig: PropTypes.array.isRequired,
    data: PropTypes.array.isRequired
};

module.exports = GridFilter;
