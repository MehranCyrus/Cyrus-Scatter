"""Shared lexical containment and ancestor checks before definition content access."""
import os
from pathlib import Path
import catalog
from contracts import RetrievalError


def corpus_location(root, path):
    root, path = Path(os.path.abspath(root)), Path(os.path.abspath(path))
    # WindowsPath containment is case insensitive. abspath collapses '..' without
    # resolving links; checking resolve() first would hide an excluded ancestor.
    if path == root or not path.is_relative_to(root):
        raise RetrievalError("corpus definition must be inside the declared repository")
    for ancestor in [*reversed(path.parents), path]:
        if catalog.is_link(ancestor.lstat()):
            raise RetrievalError("corpus definition ancestor is a link/reparse point")
    return path
