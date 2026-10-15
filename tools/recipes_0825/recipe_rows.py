"""Exact, ordered eight-field publication witness (not the older position/source probe)."""
import hashlib,json

def fingerprint(rows):
    values=[]
    for row in rows:
        assert len(row)==8
        matrix=row[0]
        transform=[float(component) for vector in [matrix.row1,matrix.row2,matrix.row3,matrix.row4] for component in [vector.x,vector.y,vector.z]]
        anchor=row[4]
        identity=row[2] if isinstance(row[2],str) else int(row[2])
        values.append([transform,int(row[1]),identity,int(row[3]),[float(anchor.x),float(anchor.y),float(anchor.z)],int(row[5]),bool(row[6]),int(row[7])])
    return hashlib.sha256(json.dumps(values,separators=(',',':'),ensure_ascii=False,allow_nan=False).encode('utf-8')).hexdigest()
