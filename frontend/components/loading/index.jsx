const styles = require('./styles');
const Loading = props => (
    <div style={styles.window}>
        <label style={styles.label}>
            {props.label}
        </label>
    </div>
);

module.exports = Loading;