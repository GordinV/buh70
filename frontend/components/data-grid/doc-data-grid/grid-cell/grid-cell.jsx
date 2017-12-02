
const PropTypes = require('prop-types');

const React = require('react'),
    flux = require('fluxify');

class GridCell extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            value: this.props.value, editable: false, readOnly: this.props.readOnly, disabled: false
        }
    }

    componentWillReceiveProps() {
        this.setState({value: this.props.value})
    }

    render() {
        let isEdit = (this.state.readOnly && !this.state.disabled) ? true : false,
            cell = this.props.cell, // параметры ячейки
            isReadOnly = this.state.readOnly,
            cellType = 'span'; // находится ли док в режиме редактирования

        isReadOnly = cell.readOnly ? true : isReadOnly; // поправка на свойство ячейки, доступна ли она редактированию
        isReadOnly = true;

        const EditElement = <span
            onClick={this.handleClick}
            className={this.props.className}>
            {this.props.value}
            </span>;

        return (
            <td ref={'cell-' + this.props.id}
                className={this.props.className}
                style={{width: cell.width}}>
                {EditElement}
            </td>
        )
    }
}


GridCell.propTypes = {
    id: PropTypes.number,
    readOnly: PropTypes.bool
}

GridCell.defaultProps = {
    id: 0,
    readOnly: false,
    value: ''
}

module.exports = GridCell;

