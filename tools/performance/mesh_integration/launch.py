"""Launch only private copies; never replace the artist's installed DLLs."""
from build import load_helper
if __name__=='__main__':
    load_helper('launch').main()
